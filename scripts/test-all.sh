#!/usr/bin/env bash
# Copyright 2026 Stefano Balzarotti
# Distributed under the terms of the GNU General Public License v3
#
# test-all.sh — run scripts/test-pkg.sh for several overlay packages, each in
# its own fresh container (PLAN.md Phase 2B). With no arguments it walks every
# package in the overlay; otherwise it tests only the atoms given.
#
# Usage:   scripts/test-all.sh [category/package ...]
# Example: scripts/test-all.sh                       # the whole overlay
#          scripts/test-all.sh dev-util/fnm x11-misc/polo
#
# Env:  KEEP_GOING=1   test every package even if some fail, then report a
#                      summary (default: fail-fast — stop at the first failure).
#       plus every knob honoured by test-pkg.sh (CONTAINER_ENGINE, TREE_MODE, …).

set -eu

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OVERLAY_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
RUNNER="${SCRIPT_DIR}/test-pkg.sh"
KEEP_GOING="${KEEP_GOING:-}"

[ -x "${RUNNER}" ] || { echo "test-all: missing runner ${RUNNER}" >&2; exit 1; }

# Packages: the atoms passed as arguments, else every cat/pkg dir (depth 3)
# holding at least one *.ebuild. cd keeps find's output as bare cat/pkg paths.
if [ "$#" -gt 0 ]; then
	packages=("$@")
else
	cd "${OVERLAY_ROOT}"
	mapfile -t packages < <(find . -mindepth 3 -maxdepth 3 -name '*.ebuild' -printf '%h\n' | sed 's,^\./,,' | sort -u)
fi
[ "${#packages[@]}" -gt 0 ] || { echo "test-all: no packages found" >&2; exit 1; }

passed=()
failed=()
for pkg in "${packages[@]}"; do
	echo "=== ${pkg} ==="
	if "${RUNNER}" "${pkg}"; then
		passed+=("${pkg}")
	else
		failed+=("${pkg}")
		if [ -z "${KEEP_GOING}" ]; then
			echo "test-all: ${pkg} failed — stopping (set KEEP_GOING=1 to continue)" >&2
			break
		fi
	fi
done

echo "=== summary: ${#passed[@]} passed, ${#failed[@]} failed ==="
if [ "${#failed[@]}" -gt 0 ]; then
	printf '  FAIL %s\n' "${failed[@]}" >&2
	exit 1
fi
echo "  all ${#passed[@]} package(s) OK"
