#!/usr/bin/env bash
# Copyright 2026 Stefano Balzarotti
# Distributed under the terms of the GNU General Public License v3
#
# test-pkg.sh — build+install ONE overlay package in a throwaway Gentoo
# container for QA (PLAN.md Phase 2B). Full isolation: each invocation starts a
# fresh stage3 container, registers this overlay, emerges the package, verifies
# it actually installed, then removes the container (foreground `run --rm`).
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
#   EMERGE_OPTS       extra args appended to `emerge -v`  (default: empty)
#   CONTAINER_OPTS    extra args for `<engine> run`       (default: empty)
#   FEATURES_DISABLE  Portage FEATURES to turn off        (default: the namespace
#                     sandboxes that need privileges unavailable in plain docker)
#   GETBINPKG         pull binary packages from a binhost (default: empty = full
#                     source build; set e.g. GETBINPKG=1 for a faster local run)
#   BINHOST           binhost sync-uri to use with GETBINPKG (default: empty =
#                     whatever the stage3 image already ships in binrepos.conf)
#
# Binary packages are never required: locally you choose source (default) or, by
# setting GETBINPKG, the binpkg-accelerated path. CI builds from source — the
# official binhost can't serve the GUI/X chain (freetype<->harfbuzz; PLAN.md 2.7).
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
STAGE3_IMAGE="${STAGE3_IMAGE:-gentoo/stage3:latest@sha256:91134e1375edb5d0b69951bab06d229e6695b66ce9726d46a5a4293fc305eb34}"
GENTOO_REPO="${GENTOO_REPO:-/var/db/repos/gentoo}"
TREE_MODE="${TREE_MODE:-auto}"
EMERGE_OPTS="${EMERGE_OPTS:-}"
CONTAINER_OPTS="${CONTAINER_OPTS:-}"
FEATURES_DISABLE="${FEATURES_DISABLE:--network-sandbox -ipc-sandbox -pid-sandbox}"
GETBINPKG="${GETBINPKG:-}"
BINHOST="${BINHOST:-}"

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
engine_args+=(--volume "${OVERLAY_ROOT}:/var/db/repos/${REPO_NAME}:ro")
engine_args+=(--volume "${SCRIPT_DIR}/test-pkg-container.sh:/test-pkg-container.sh:ro")
engine_args+=(--volume "${SCRIPT_DIR}/test-portage:/test-portage:ro")
if [ "${TREE_MODE}" = "bind" ]; then
	engine_args+=(--volume "${GENTOO_REPO}:/var/db/repos/gentoo:ro")
fi
# shellcheck disable=SC2206  # CONTAINER_OPTS is intentionally word-split
[ -n "${CONTAINER_OPTS}" ] && engine_args+=(${CONTAINER_OPTS})
engine_args+=("${STAGE3_IMAGE}")
# Provisioning + build run inside the container by a separate, shellcheck-linted
# script (mounted read-only above); its ${VAR}s come from the --env knobs.
engine_args+=(bash /test-pkg-container.sh)

# --- run -------------------------------------------------------------------
log "container: ${CONTAINER_ENGINE} ${STAGE3_IMAGE} | tree: ${TREE_MODE} | binpkg: ${GETBINPKG:-no} | pkg: ${PKG}"
if "${CONTAINER_ENGINE}" "${engine_args[@]}"; then
	log "PASS ${PKG}"
else
	die "FAIL ${PKG}"
fi
