#!/usr/bin/env bash
# Copyright 2026 Stefano Balzarotti
# Distributed under the terms of the GNU General Public License v3
#
# livecheck-container.sh — runs INSIDE the gentoo/stage3 container started by
# scripts/livecheck-ci.sh; mounted read-only at /livecheck-container.sh. Do not
# run it on the host.
#
# The overlay is mounted READ-WRITE at /var/db/repos/${REPO_NAME}. It registers
# the overlay, installs livecheck, then runs livecheck --auto, which rewrites the
# bumped ebuilds and regenerates their Manifests — NOT --git: the changes are left
# uncommitted so the workflow's create-pull-request step commits + opens the PR.
#
# Portage config comes from the scripts/test-portage/*.in templates (mounted at
# /test-portage); the sed calls only fill @TOKEN@ placeholders.
#
# Environment (set via the container engine's --env): REPO_NAME required;
# FEATURES_DISABLE and GITHUB_TOKEN (authenticates livecheck's API calls) optional.

set -eu

REPO_NAME="${REPO_NAME:?REPO_NAME is required}"
FEATURES_DISABLE="${FEATURES_DISABLE:--network-sandbox -ipc-sandbox -pid-sandbox}"
CONF_DIR=/test-portage
OVERLAY="/var/db/repos/${REPO_NAME}"
VENV=/opt/livecheck-venv

echo ">> registering overlay '${REPO_NAME}'"
mkdir -p /etc/portage/repos.conf
sed "s|@REPO_NAME@|${REPO_NAME}|g" \
	"${CONF_DIR}/repos.conf.in" > "/etc/portage/repos.conf/${REPO_NAME}.conf"

# Throwaway container: accept any licence and relax the sandboxes plain docker
# can't grant, so emerge + distfile fetches run.
sed "s|@FEATURES_DISABLE@|${FEATURES_DISABLE}|g" \
	"${CONF_DIR}/make.conf.in" >> /etc/portage/make.conf

echo ">> fetching gentoo tree (emerge-webrsync)"
emerge-webrsync

echo ">> installing livecheck from PyPI into a venv"
# livecheck goes into its own venv, never into the system site-packages: Portage
# strips RECORD from the dist-info of the Python packages it installs, so pip
# cannot upgrade one in place and aborts (uninstall-no-record-file) as soon as a
# livecheck dependency outgrows the stage3's version. --system-site-packages
# keeps Portage's `portage` module — which livecheck imports — visible, and the
# venv bootstraps its own pip from ensurepip, so none has to be emerged.
python3 -m venv --system-site-packages "${VENV}"

# Put the venv's bin dir first so `pip`, `python3` and `livecheck` all resolve to it.
PATH="${VENV}/bin:${PATH}"
export PATH

# livecheck's wheel omits 'packaging'; keyrings.alt provides a keyring backend
# (see below).
pip install --root-user-action=ignore --quiet livecheck packaging keyrings.alt

# livecheck reads its token via python-keyring; a bare container has no backend and
# raises NoKeyringError. keyrings.alt's file backend returns None when unset (no
# crash); seed GITHUB_TOKEN when present so API calls are authenticated (the
# unauthenticated rate limit is shared per-IP on Actions runners).
export PYTHON_KEYRING_BACKEND=keyrings.alt.file.PlaintextKeyring
if [ -n "${GITHUB_TOKEN:-}" ]; then
	echo ">> seeding GitHub token into the keyring for livecheck"
	python3 -c "import keyring, os; keyring.set_password('github.com', 'livecheck', os.environ['GITHUB_TOKEN'])"
fi

echo ">> livecheck --auto (rewrite bumped ebuilds + regenerate their Manifests, left uncommitted)"
"${OVERLAY}/scripts/livecheck.sh" --auto
