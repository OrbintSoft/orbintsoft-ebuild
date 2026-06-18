#!/usr/bin/env bash
# Copyright 2026 Stefano Balzarotti
# Distributed under the terms of the GNU General Public License v3
#
# livecheck-container.sh — runs INSIDE the throwaway gentoo/stage3 container
# driven by scripts/livecheck-ci.sh (PLAN.md Phase 3.5, the weekly bump job). It
# is mounted read-only at /livecheck-container.sh and invoked there; do not run
# it on the host.
#
# Unlike the test harness, the overlay is mounted READ-WRITE at
# /var/db/repos/${REPO_NAME}: livecheck rewrites the bumped ebuilds and pkgdev
# regenerates the Manifest in place, so the changes land back in the workspace
# for the workflow's create-pull-request step. We run livecheck WITHOUT --git
# (no commit here) and regenerate the Manifest explicitly, leaving everything
# uncommitted for peter-evans/create-pull-request to commit + open the PR.
#
# Portage config is filled from the scripts/test-portage/*.in templates (shared
# with the test harness, mounted read-only at /test-portage); the sed calls only
# substitute @TOKEN@ placeholders, so config syntax stays in its own files
# (CLAUDE.md Rule 13) rather than in heredocs.
#
# Configuration arrives as environment variables (set by livecheck-ci.sh via the
# container engine's --env): REPO_NAME is required; FEATURES_DISABLE and
# GITHUB_TOKEN (used to authenticate livecheck's GitHub API calls) are optional.

set -eu

REPO_NAME="${REPO_NAME:?REPO_NAME is required}"
FEATURES_DISABLE="${FEATURES_DISABLE:--network-sandbox -ipc-sandbox -pid-sandbox}"
CONF_DIR=/test-portage
OVERLAY="/var/db/repos/${REPO_NAME}"

echo ">> registering overlay '${REPO_NAME}'"
mkdir -p /etc/portage/repos.conf
sed "s|@REPO_NAME@|${REPO_NAME}|g" \
	"${CONF_DIR}/repos.conf.in" > "/etc/portage/repos.conf/${REPO_NAME}.conf"

# Throwaway container: accept any licence and relax the namespace sandboxes that
# need privileges plain docker does not grant (so emerge + distfile fetches run).
sed "s|@FEATURES_DISABLE@|${FEATURES_DISABLE}|g" \
	"${CONF_DIR}/make.conf.in" >> /etc/portage/make.conf

echo ">> fetching gentoo tree (emerge-webrsync)"
emerge-webrsync

echo ">> installing tooling (pkgdev + pip, then livecheck from PyPI)"
emerge --oneshot --quiet-build=y dev-python/pip dev-util/pkgdev
# stage3's python is externally-managed (PEP 668); --break-system-packages is fine
# in a disposable container. livecheck's wheel omits the 'packaging' runtime dep;
# keyrings.alt gives python-keyring a working file backend (see below).
pip install --break-system-packages --root-user-action=ignore --quiet \
	livecheck packaging keyrings.alt

# Make sure pip's console-script dir (where the `livecheck` entry point landed) is
# on PATH, so the wrapper's `command -v livecheck` finds it regardless of scheme.
PATH="$(python3 -c 'import sysconfig; print(sysconfig.get_path("scripts"))'):${PATH}"
export PATH

# livecheck reads API tokens via python-keyring; a bare container has no keyring
# backend and would raise NoKeyringError. keyrings.alt's plaintext file backend
# returns None when nothing is stored (so unauthenticated lookups don't crash). If
# GITHUB_TOKEN is present (CI forwards it), seed it so the GitHub API calls are
# authenticated and avoid the shared unauthenticated rate limit.
export PYTHON_KEYRING_BACKEND=keyrings.alt.file.PlaintextKeyring
if [ -n "${GITHUB_TOKEN:-}" ]; then
	echo ">> seeding GitHub token into the keyring for livecheck"
	python3 -c "import keyring, os; keyring.set_password('github.com', 'livecheck', os.environ['GITHUB_TOKEN'])"
fi

echo ">> livecheck --auto (rewrite bumped ebuilds, left uncommitted)"
"${OVERLAY}/scripts/livecheck.sh" --auto

echo ">> regenerating Manifests (pkgdev manifest)"
cd "${OVERLAY}"
pkgdev manifest
