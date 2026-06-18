#!/usr/bin/env bash
# Copyright 2026 Stefano Balzarotti
# Distributed under the terms of the GNU General Public License v3
#
# livecheck.sh — thin wrapper around Tatsh/livecheck (the ebuild bump engine,
# PLAN.md Phase 3.5). Runs livecheck against THIS overlay only: with no package
# arguments it enumerates the overlay via scripts/list-packages.sh (the single
# source of truth) so it never wanders into the gentoo tree. Report-only by
# default; --auto rewrites ebuilds, --git additionally commits + regenerates the
# Manifest via pkgdev (implies --auto). The /bump skill (Phase 3.6) and the
# weekly CI job both call this wrapper instead of invoking livecheck directly.
#
# Usage:   scripts/livecheck.sh [--auto] [--git] [cat/pkg ...]
#          scripts/livecheck.sh                 # report new versions, whole overlay
#          scripts/livecheck.sh media-fonts/nerd-fonts
#          scripts/livecheck.sh --git           # bump every overlay package + commit
#
# livecheck reads the overlay through Portage, so the overlay must be a repo
# configured in repos.conf — register it once with `make install`. livecheck is
# distributed via tatsh-overlay or PyPI (`pip install livecheck`) and needs a
# configured Portage environment + pkgdev (both present on a Gentoo host).
# LIVECHECK_WORKDIR overrides the tree root passed via -W (defaults to overlay root).

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OVERLAY_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
WORKDIR="${LIVECHECK_WORKDIR:-${OVERLAY_ROOT}}"

usage() { sed -n '5,22p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; }

auto=0
git=0
pkgs=()
while [ "$#" -gt 0 ]; do
	case "$1" in
		-h|--help) usage; exit 0 ;;
		--auto) auto=1 ;;
		--git) git=1 ;;
		-*) echo "livecheck.sh: unknown option '$1'" >&2; exit 2 ;;
		*) pkgs+=("$1") ;;
	esac
	shift
done

# --git is a no-op without rewriting, so it implies --auto.
[ "${git}" -eq 1 ] && auto=1

if ! command -v livecheck >/dev/null 2>&1; then
	echo "livecheck.sh: 'livecheck' not found in PATH." >&2
	echo "  Install it from tatsh-overlay (emerge livecheck) or PyPI (pip install livecheck)." >&2
	exit 127
fi

flags=(-W "${WORKDIR}")
[ "${auto}" -eq 1 ] && flags+=(--auto-update)
[ "${git}" -eq 1 ] && flags+=(--git)

# No explicit packages => the whole overlay (bounded to our tree, never gentoo's).
if [ "${#pkgs[@]}" -eq 0 ]; then
	mapfile -t pkgs < <("${SCRIPT_DIR}/list-packages.sh")
fi

cd "${OVERLAY_ROOT}"
exec livecheck "${flags[@]}" "${pkgs[@]}"
