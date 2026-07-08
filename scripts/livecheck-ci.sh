#!/usr/bin/env bash
# Copyright 2026 Stefano Balzarotti
# Distributed under the terms of the GNU General Public License v3
#
# livecheck-ci.sh — run the bump engine in a throwaway gentoo/stage3 container
# with the overlay mounted READ-WRITE, so the bumped ebuilds + regenerated
# Manifest land back in the workspace for the caller to open a PR. In-container
# provisioning lives in the companion scripts/livecheck-container.sh.
#
# CI-only: needs a container engine and an x86_64 gentoo/stage3 image. For a local
# bump run `make livecheck` (scripts/livecheck.sh) directly on a Gentoo host.
#
# Environment knobs (all optional):
#   CONTAINER_ENGINE  container CLI                  (default: docker)
#   STAGE3_IMAGE      stage3 image to run            (default: gentoo/stage3:latest,
#                     digest-pinned below; Renovate keeps the digest current)
#   CONTAINER_OPTS    extra args for `<engine> run`  (default: empty)
#   GITHUB_TOKEN      forwarded so livecheck authenticates GitHub API calls (default: unset)

set -euo pipefail

CONTAINER_ENGINE="${CONTAINER_ENGINE:-docker}"
# Digest-pinned; Renovate refreshes the rolling `latest` tag's digest (also pinned
# the same way in scripts/test-pkg.sh; both matched by the manager in renovate.json5).
# renovate: datasource=docker depName=gentoo/stage3
STAGE3_IMAGE="${STAGE3_IMAGE:-gentoo/stage3:latest@sha256:2fb4d12e05d99f54ca805653687d96bc79370ee333e314229436bc383e504622}"
CONTAINER_OPTS="${CONTAINER_OPTS:-}"

die() { echo "livecheck-ci: $*" >&2; exit 1; }
log() { echo ">> $*"; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OVERLAY_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
[ -f "${SCRIPT_DIR}/livecheck-container.sh" ] \
	|| die "missing companion script ${SCRIPT_DIR}/livecheck-container.sh"
[ -d "${SCRIPT_DIR}/test-portage" ] \
	|| die "missing portage-config templates dir ${SCRIPT_DIR}/test-portage"
[ -f "${OVERLAY_ROOT}/profiles/repo_name" ] \
	|| die "no profiles/repo_name under ${OVERLAY_ROOT} — is this the overlay root?"
REPO_NAME="$(cat "${OVERLAY_ROOT}/profiles/repo_name")"
[ -n "${REPO_NAME}" ] || die "profiles/repo_name is empty"
command -v "${CONTAINER_ENGINE}" >/dev/null 2>&1 \
	|| die "container engine '${CONTAINER_ENGINE}' not found on PATH"

# Overlay mounted READ-WRITE so the bump persists back to the workspace; the
# templates and the companion script are read-only.
engine_args=(run --rm)
engine_args+=(--env "REPO_NAME=${REPO_NAME}")
# Forward the GitHub token (if any) so livecheck authenticates its API calls.
[ -n "${GITHUB_TOKEN:-}" ] && engine_args+=(--env "GITHUB_TOKEN=${GITHUB_TOKEN}")
engine_args+=(--volume "${OVERLAY_ROOT}:/var/db/repos/${REPO_NAME}")
engine_args+=(--volume "${SCRIPT_DIR}/test-portage:/test-portage:ro")
engine_args+=(--volume "${SCRIPT_DIR}/livecheck-container.sh:/livecheck-container.sh:ro")
# shellcheck disable=SC2206  # CONTAINER_OPTS is intentionally word-split
[ -n "${CONTAINER_OPTS}" ] && engine_args+=(${CONTAINER_OPTS})
engine_args+=("${STAGE3_IMAGE}")
engine_args+=(bash /livecheck-container.sh)

log "container: ${CONTAINER_ENGINE} ${STAGE3_IMAGE} | overlay: ${REPO_NAME} (rw)"
exec "${CONTAINER_ENGINE}" "${engine_args[@]}"
