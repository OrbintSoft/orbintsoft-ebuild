#!/usr/bin/env bash
# Copyright 2026 Stefano Balzarotti
# Distributed under the terms of the GNU General Public License v3
#
# test-pkg-container.sh — runs INSIDE the throwaway gentoo/stage3 container
# driven by scripts/test-pkg.sh (PLAN.md Phase 2B). It is mounted read-only at
# /test-pkg-container.sh and invoked there; do not run it on the host.
#
# Configuration arrives as environment variables (set by test-pkg.sh via the
# container engine's --env): PKG, REPO_NAME, TREE_MODE are required;
# EMERGE_OPTS and FEATURES_DISABLE are optional. Assigning from self both
# documents the contract and satisfies shellcheck (vars are env-injected).

set -eu

PKG="${PKG:?PKG is required}"
REPO_NAME="${REPO_NAME:?REPO_NAME is required}"
TREE_MODE="${TREE_MODE:?TREE_MODE is required}"
EMERGE_OPTS="${EMERGE_OPTS:-}"
FEATURES_DISABLE="${FEATURES_DISABLE:-}"

echo ">> registering overlay '${REPO_NAME}'"
mkdir -p /etc/portage/repos.conf
cat > "/etc/portage/repos.conf/${REPO_NAME}.conf" <<EOF
[${REPO_NAME}]
location = /var/db/repos/${REPO_NAME}
masters = gentoo
auto-sync = no
EOF

# Live ebuilds carry empty KEYWORDS (== **); accept them for this overlay only.
mkdir -p /etc/portage/package.accept_keywords
echo "*/*::${REPO_NAME} **" > "/etc/portage/package.accept_keywords/${REPO_NAME}"

# Throwaway container: accept any licence and relax the namespace sandboxes that
# need privileges plain docker does not grant. ${FEATURES} stays literal so
# Portage expands it; FEATURES_DISABLE is substituted here.
{
	echo 'ACCEPT_LICENSE="*"'
	echo "FEATURES=\"\${FEATURES} ${FEATURES_DISABLE}\""
} >> /etc/portage/make.conf

if [ "${TREE_MODE}" = "webrsync" ]; then
	echo ">> fetching gentoo tree (emerge-webrsync)"
	emerge-webrsync
fi

echo ">> emerge -v ${EMERGE_OPTS} ${PKG}"
# EMERGE_OPTS must word-split into separate emerge arguments.
# shellcheck disable=SC2086
emerge -v ${EMERGE_OPTS} "${PKG}"

echo ">> verifying ${PKG} is installed"
if command -v qlist >/dev/null 2>&1; then
	[ -n "$(qlist -I "${PKG}")" ] || { echo "qlist: ${PKG} not installed" >&2; exit 1; }
else
	# portage-utils absent from this stage3 — check Portage's installed-package DB
	ls -d "/var/db/pkg/${PKG}"-* >/dev/null 2>&1 \
		|| { echo "vdb: ${PKG} not installed" >&2; exit 1; }
fi
echo ">> OK: ${PKG} built and installed"
