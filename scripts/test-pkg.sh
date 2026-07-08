#!/usr/bin/env bash
# Copyright 2026 Stefano Balzarotti
# Distributed under the terms of the GNU General Public License v3
#
# test-pkg.sh — build+install ONE overlay package in a throwaway Gentoo
# container for QA. Full isolation: each invocation starts a fresh stage3
# container, registers this overlay, emerges the package, verifies it actually
# installed, then removes the container (foreground `run --rm`).
#
# Usage:   scripts/test-pkg.sh <category/package>
# Example: scripts/test-pkg.sh app-admin/pamtester
#
# The in-container provisioning + build lives in the companion script
# scripts/test-pkg-container.sh (mounted read-only and run inside the
# container) so it gets shellcheck-linted instead of hiding in a heredoc.
#
# Environment knobs (all optional):
#   CONTAINER_ENGINE  container CLI                       (default: docker)
#   STAGE3_IMAGE      stage3 image to run                 (default: gentoo/stage3:latest,
#                     digest-pinned in-script; Renovate keeps the digest current)
#   GENTOO_REPO       host gentoo ebuild tree to bind     (default: /var/db/repos/gentoo)
#   TREE_MODE         bind | webrsync | auto              (default: auto)
#   HASKELL_OVERLAY   force-enable the gentoo-haskell overlay (default: empty =
#                     enabled only when the ebuild's QA-TEST says overlay=haskell)
#   HASKELL_REPO      host gentoo-haskell tree to bind     (default: /var/db/repos/haskell)
#   HASKELL_URL       gentoo-haskell repo for the tarball fetch (CI, no host tree)
#   HASKELL_REF       branch/tag/commit to fetch           (default: master)
#   EMERGE_OPTS       extra args appended to `emerge -v`  (default: empty)
#   CONTAINER_OPTS    extra args for `<engine> run`       (default: empty)
#   FEATURES_DISABLE  Portage FEATURES to turn off        (default: the namespace
#                     sandboxes that need privileges unavailable in plain docker)
#   GETBINPKG         pull binary packages from a binhost (default: empty = full
#                     source build; set e.g. GETBINPKG=1 for a faster local run)
#   BINHOST           binhost sync-uri to use with GETBINPKG (default: empty =
#                     whatever the stage3 image already ships in binrepos.conf)
#   BINPKG_RESPECT_USE --binpkg-respect-use with GETBINPKG (default: n = use a
#                     binpkg despite a USE mismatch; y = rebuild from source on
#                     mismatch). n lets the binhost serve the desktop/X chain.
#   STRATEGY          test build strategy override: source | binpkg |
#                     binpkg-respect-use [image=<tag>]. Default: the ebuild's
#                     `# QA-TEST:` directive, else source.
#   FALLBACK_SOURCE   on a binpkg failure, retry from source (default: 1).
#
# How the package is built is declarative per-package: each ebuild carries a
# `# QA-TEST: <strategy>` comment (default 'source', which always works). The
# binhost cannot consistently serve the whole suite (systemd into openrc +
# abi_x86_32 multilib + version skew), so binpkg is opt-in per package and falls
# back to source. STRATEGY/GETBINPKG env override the directive.
#
# TREE_MODE explained:
#   bind      bind-mount the host gentoo tree read-only at /var/db/repos/gentoo
#             (fast — no download; for local runs on a Gentoo host).
#   webrsync  fetch a fresh tree snapshot inside the container via
#             emerge-webrsync (self-contained; for CI / non-Gentoo hosts).
#   auto      bind if GENTOO_REPO looks like a tree, otherwise webrsync.

set -euo pipefail

CONTAINER_ENGINE="${CONTAINER_ENGINE:-docker}"
# Digest-pinned for reproducible test containers; Renovate bumps the digest of the
# rolling `latest` tag (datasource=docker annotation below; see renovate.json5).
# renovate: datasource=docker depName=gentoo/stage3
STAGE3_IMAGE="${STAGE3_IMAGE:-gentoo/stage3:latest@sha256:2fb4d12e05d99f54ca805653687d96bc79370ee333e314229436bc383e504622}"
GENTOO_REPO="${GENTOO_REPO:-/var/db/repos/gentoo}"
TREE_MODE="${TREE_MODE:-auto}"
EMERGE_OPTS="${EMERGE_OPTS:-}"
CONTAINER_OPTS="${CONTAINER_OPTS:-}"
FEATURES_DISABLE="${FEATURES_DISABLE:--network-sandbox -ipc-sandbox -pid-sandbox}"
GETBINPKG="${GETBINPKG:-}"
BINHOST="${BINHOST:-}"
BINPKG_RESPECT_USE="${BINPKG_RESPECT_USE:-n}"
STRATEGY="${STRATEGY:-}"
FALLBACK_SOURCE="${FALLBACK_SOURCE:-1}"
# Optional gentoo-haskell overlay, requested per-package via `# QA-TEST: ...
# overlay=haskell`, so Haskell deps build from the same overlay a Gentoo Haskell
# setup uses (priority 50) instead of ::gentoo. Bind-mounted from the host when
# present (fast, no network), else fetched as a tarball inside the container (CI).
HASKELL_OVERLAY="${HASKELL_OVERLAY:-}"
HASKELL_REPO="${HASKELL_REPO:-/var/db/repos/haskell}"
HASKELL_URL="${HASKELL_URL:-https://github.com/gentoo-haskell/gentoo-haskell}"
HASKELL_REF="${HASKELL_REF:-master}"
HASKELL_TREE_MODE=""

die() { echo "test-pkg: $*" >&2; exit 1; }
log() { echo ">> $*"; }

# --- arguments -------------------------------------------------------------
[ "$#" -eq 1 ] || die "usage: $0 <category/package>"
PKG="$1"
case "${PKG}" in
	*/*) : ;;
	*) die "expected an atom of the form category/package, got '${PKG}'" ;;
esac

# --- overlay location ------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OVERLAY_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
[ -f "${SCRIPT_DIR}/test-pkg-container.sh" ] \
	|| die "missing companion script ${SCRIPT_DIR}/test-pkg-container.sh"
[ -d "${SCRIPT_DIR}/test-portage" ] \
	|| die "missing portage-config templates dir ${SCRIPT_DIR}/test-portage"
[ -f "${OVERLAY_ROOT}/profiles/repo_name" ] \
	|| die "no profiles/repo_name under ${OVERLAY_ROOT} — is this the overlay root?"
REPO_NAME="$(cat "${OVERLAY_ROOT}/profiles/repo_name")"
[ -n "${REPO_NAME}" ] || die "profiles/repo_name is empty"
[ -d "${OVERLAY_ROOT}/$(dirname "${PKG}")/$(basename "${PKG}")" ] \
	|| die "package '${PKG}' not found in overlay ${OVERLAY_ROOT}"

# --- test strategy (per-package) -------------------------------------------
# How to build the package for the test: 'source' (default, always works) or a
# faster binpkg path. Precedence: STRATEGY env > legacy non-empty GETBINPKG env >
# the ebuild's `# QA-TEST:` directive > 'source'. The directive value is a method
# (source | binpkg | binpkg-respect-use) with an optional `image=<tag>` modifier.
if [ -n "${STRATEGY}" ] || [ -z "${GETBINPKG}" ]; then
	if [ -z "${STRATEGY}" ]; then
		qa_line="$(grep -hm1 '^#[[:space:]]*QA-TEST:' \
			"${OVERLAY_ROOT}/${PKG}"/*.ebuild 2>/dev/null || true)"
		qa_line="${qa_line#*QA-TEST:}"   # value after the marker
		STRATEGY="${qa_line%%#*}"        # drop any trailing inline comment
	fi
	read -r -a strat_parts <<<"${STRATEGY}"
	strat_method="${strat_parts[0]:-source}"
	for opt in ${strat_parts[@]+"${strat_parts[@]:1}"}; do
		case "${opt}" in
			image=*)   STAGE3_IMAGE="${opt#image=}" ;;
			overlay=*) case "${opt#overlay=}" in
					haskell) HASKELL_OVERLAY=1 ;;
					*) die "unknown QA-TEST overlay '${opt#overlay=}' for ${PKG}" ;;
				esac ;;
		esac
	done
	case "${strat_method}" in
		source)             GETBINPKG="" ;;
		binpkg)             GETBINPKG=1; BINPKG_RESPECT_USE=n ;;
		binpkg-respect-use) GETBINPKG=1; BINPKG_RESPECT_USE=y ;;
		*) die "unknown QA-TEST strategy '${strat_method}' for ${PKG}" ;;
	esac
	STRATEGY="${strat_method}"
fi

# --- gentoo tree mode ------------------------------------------------------
if [ "${TREE_MODE}" = "auto" ]; then
	if [ -d "${GENTOO_REPO}/profiles" ]; then
		TREE_MODE="bind"
	else
		TREE_MODE="webrsync"
	fi
fi
case "${TREE_MODE}" in
	bind)
		[ -d "${GENTOO_REPO}/profiles" ] \
			|| die "TREE_MODE=bind but '${GENTOO_REPO}' is not a gentoo tree" ;;
	webrsync) : ;;
	*) die "TREE_MODE must be bind, webrsync or auto (got '${TREE_MODE}')" ;;
esac

# --- gentoo-haskell overlay mode (only when the package requested it) -------
# Bind the host overlay if it is checked out (fast, no network); otherwise fetch
# a tarball inside the container (CI on a non-Gentoo host). Mirrors TREE_MODE.
if [ -n "${HASKELL_OVERLAY}" ]; then
	if [ -d "${HASKELL_REPO}/profiles" ]; then
		HASKELL_TREE_MODE="bind"
	else
		HASKELL_TREE_MODE="fetch"
	fi
fi

command -v "${CONTAINER_ENGINE}" >/dev/null 2>&1 \
	|| die "container engine '${CONTAINER_ENGINE}' not found on PATH"

# --- assemble the engine invocation ----------------------------------------
# Knobs travel into the container as env vars; volumes are read-only (the
# container is the throwaway, so Portage's own sandboxes can be relaxed).
engine_args=(run --rm)
engine_args+=(--env "PKG=${PKG}")
engine_args+=(--env "REPO_NAME=${REPO_NAME}")
engine_args+=(--env "TREE_MODE=${TREE_MODE}")
engine_args+=(--env "EMERGE_OPTS=${EMERGE_OPTS}")
engine_args+=(--env "FEATURES_DISABLE=${FEATURES_DISABLE}")
engine_args+=(--env "GETBINPKG=${GETBINPKG}")
engine_args+=(--env "BINHOST=${BINHOST}")
engine_args+=(--env "BINPKG_RESPECT_USE=${BINPKG_RESPECT_USE}")
engine_args+=(--env "FALLBACK_SOURCE=${FALLBACK_SOURCE}")
engine_args+=(--env "HASKELL_OVERLAY=${HASKELL_OVERLAY}")
engine_args+=(--env "HASKELL_TREE_MODE=${HASKELL_TREE_MODE}")
engine_args+=(--env "HASKELL_URL=${HASKELL_URL}")
engine_args+=(--env "HASKELL_REF=${HASKELL_REF}")
engine_args+=(--volume "${OVERLAY_ROOT}:/var/db/repos/${REPO_NAME}:ro")
engine_args+=(--volume "${SCRIPT_DIR}/test-pkg-container.sh:/test-pkg-container.sh:ro")
engine_args+=(--volume "${SCRIPT_DIR}/test-portage:/test-portage:ro")
if [ "${TREE_MODE}" = "bind" ]; then
	engine_args+=(--volume "${GENTOO_REPO}:/var/db/repos/gentoo:ro")
fi
if [ "${HASKELL_TREE_MODE}" = "bind" ]; then
	engine_args+=(--volume "${HASKELL_REPO}:/var/db/repos/haskell:ro")
fi
# shellcheck disable=SC2206  # CONTAINER_OPTS is intentionally word-split
[ -n "${CONTAINER_OPTS}" ] && engine_args+=(${CONTAINER_OPTS})
engine_args+=("${STAGE3_IMAGE}")
# Provisioning + build run inside the container by a separate, shellcheck-linted
# script (mounted read-only above); its ${VAR}s come from the --env knobs.
engine_args+=(bash /test-pkg-container.sh)

# --- run -------------------------------------------------------------------
log "container: ${CONTAINER_ENGINE} ${STAGE3_IMAGE} | tree: ${TREE_MODE} | haskell: ${HASKELL_TREE_MODE:-no} | strategy: ${STRATEGY:-legacy} | binpkg: ${GETBINPKG:-no} | pkg: ${PKG}"
if "${CONTAINER_ENGINE}" "${engine_args[@]}"; then
	log "PASS ${PKG}"
else
	die "FAIL ${PKG}"
fi
