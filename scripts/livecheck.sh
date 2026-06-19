#!/usr/bin/env bash
# Copyright 2026 Stefano Balzarotti
# Distributed under the terms of the GNU General Public License v3
#
# livecheck.sh — check the overlay's packages for new upstream releases with
# Tatsh/livecheck. With no package arguments it checks every overlay package
# (enumerated via list-packages.sh, so it never wanders into the gentoo tree).
# Report-only by default; --auto rewrites the bumped ebuilds and regenerates their
# Manifests, --git additionally commits the result (implies --auto).
#
# Usage:   scripts/livecheck.sh [--auto] [--git] [cat/pkg ...]
#          scripts/livecheck.sh                       # report, whole overlay
#          scripts/livecheck.sh media-fonts/nerd-fonts
#          scripts/livecheck.sh --git                 # bump everything + commit
#
# Requires livecheck (pip install livecheck, or tatsh-overlay) and the overlay
# registered as a Portage repo (make install). LIVECHECK_WORKDIR overrides the
# tree root passed to livecheck via -W (default: the overlay root).

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OVERLAY_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
WORKDIR="${LIVECHECK_WORKDIR:-${OVERLAY_ROOT}}"

usage() { sed -n '5,18p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; }

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
