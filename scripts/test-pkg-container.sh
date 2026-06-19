#!/usr/bin/env bash
# Copyright 2026 Stefano Balzarotti
# Distributed under the terms of the GNU General Public License v3
#
# test-pkg-container.sh — runs INSIDE the throwaway gentoo/stage3 container
# driven by scripts/test-pkg.sh (PLAN.md Phase 2B). It is mounted read-only at
# /test-pkg-container.sh and invoked there; do not run it on the host.
#
# The Portage config it installs lives in real files — scripts/test-portage/*.in,
# mounted read-only at /test-portage — not in heredocs: this script only fills
# their @TOKEN@ placeholders with sed, so each config is authored/linted as its
# own format instead of as a string embedded in bash.
#
# Configuration arrives as environment variables (set by test-pkg.sh via the
# container engine's --env): PKG, REPO_NAME, TREE_MODE are required;
# EMERGE_OPTS, FEATURES_DISABLE, GETBINPKG, BINHOST and BINPKG_RESPECT_USE are
# optional. Assigning from self documents the contract and satisfies shellcheck
# (env-injected).

set -eu

PKG="${PKG:?PKG is required}"
REPO_NAME="${REPO_NAME:?REPO_NAME is required}"
TREE_MODE="${TREE_MODE:?TREE_MODE is required}"
EMERGE_OPTS="${EMERGE_OPTS:-}"
FEATURES_DISABLE="${FEATURES_DISABLE:-}"
GETBINPKG="${GETBINPKG:-}"
BINHOST="${BINHOST:-}"
BINPKG_RESPECT_USE="${BINPKG_RESPECT_USE:-n}"

# Portage-config templates mounted read-only by test-pkg.sh; the sed calls below
# fill their @TOKEN@ placeholders. Config syntax lives in these files, not here.
CONF_DIR=/test-portage

echo ">> registering overlay '${REPO_NAME}'"
mkdir -p /etc/portage/repos.conf
sed "s|@REPO_NAME@|${REPO_NAME}|g" \
	"${CONF_DIR}/repos.conf.in" > "/etc/portage/repos.conf/${REPO_NAME}.conf"

mkdir -p /etc/portage/package.accept_keywords
sed "s|@REPO_NAME@|${REPO_NAME}|g" \
	"${CONF_DIR}/package.accept_keywords.in" > "/etc/portage/package.accept_keywords/${REPO_NAME}"

sed "s|@FEATURES_DISABLE@|${FEATURES_DISABLE}|g" \
	"${CONF_DIR}/make.conf.in" >> /etc/portage/make.conf

if [ "${TREE_MODE}" = "webrsync" ]; then
	echo ">> fetching gentoo tree (emerge-webrsync)"
	emerge-webrsync
fi

# Binary packages: off by default (full source build). When GETBINPKG is set we
# pull prebuilt packages from a binhost; BINHOST overrides the sync-uri the stage3
# image already ships in binrepos.conf. BINPKG_RESPECT_USE (default n) sets
# --binpkg-respect-use: n accepts a binpkg even when its USE differs from this
# container's profile, so the binhost's desktop/X chain (gtk+, mesa,
# freetype[harfbuzz]) — built with richer USE than a base stage3 — is used as-is
# instead of rebuilt from source; y rejects USE-mismatched binpkgs and falls back
# to source. Only binhost deps are affected; overlay ebuilds always build from source.
emerge_opts=()
if [ -n "${GETBINPKG}" ]; then
	echo ">> binary packages enabled (getbinpkg, binpkg-respect-use=${BINPKG_RESPECT_USE})"
	if [ -n "${BINHOST}" ]; then
		mkdir -p /etc/portage/binrepos.conf
		sed "s|@BINHOST@|${BINHOST}|g" \
			"${CONF_DIR}/binrepos.conf.in" > /etc/portage/binrepos.conf/test-binhost.conf
	fi
	emerge_opts+=(--getbinpkg=y "--binpkg-respect-use=${BINPKG_RESPECT_USE}")
fi

# Throwaway container: let Portage auto-apply the USE/keyword changes its
# dependency graph needs (e.g. a GTK/Qt chain wants cairo[X], freetype[harfbuzz])
# and carry on, instead of stopping at "USE changes necessary to proceed". Safe
# because the container is disposable and CONFIG_PROTECT is disabled (make.conf.in),
# so the writes land immediately. Licences are already opened via ACCEPT_LICENSE.
emerge_opts+=(--autounmask=y --autounmask-use=y --autounmask-write=y --autounmask-continue=y)

echo ">> emerge -v ${emerge_opts[*]} ${EMERGE_OPTS} ${PKG}"
# EMERGE_OPTS must word-split into separate emerge arguments.
# shellcheck disable=SC2086
emerge -v "${emerge_opts[@]}" ${EMERGE_OPTS} "${PKG}"

echo ">> verifying ${PKG} is installed"
if command -v qlist >/dev/null 2>&1; then
	[ -n "$(qlist -I "${PKG}")" ] || { echo "qlist: ${PKG} not installed" >&2; exit 1; }
else
	# portage-utils absent from this stage3 — check Portage's installed-package DB
	ls -d "/var/db/pkg/${PKG}"-* >/dev/null 2>&1 \
		|| { echo "vdb: ${PKG} not installed" >&2; exit 1; }
fi
echo ">> OK: ${PKG} built and installed"
