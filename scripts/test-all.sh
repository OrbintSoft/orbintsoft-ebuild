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
#          SAMPLE=1 scripts/test-all.sh              # one random package
#
# Env:  KEEP_GOING=1   test every package even if some fail, then report a
#                      summary (default: fail-fast — stop at the first failure).
#       SAMPLE=N       with no atom args, test N random packages (a smoke test;
#                      mirrors the CI random pick on harness-only changes).
#       plus every knob honoured by test-pkg.sh (CONTAINER_ENGINE, TREE_MODE, …).

set -eu

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RUNNER="${SCRIPT_DIR}/test-pkg.sh"
KEEP_GOING="${KEEP_GOING:-}"
SAMPLE="${SAMPLE:-}"

[ -x "${RUNNER}" ] || { echo "test-all: missing runner ${RUNNER}" >&2; exit 1; }

# Packages to test, in priority order: explicit atoms (args) win; else SAMPLE=N
# picks N random packages (smoke test, mirrors the CI random pick); else the whole
# overlay from the shared discovery script (single source of truth, also used by
# the CI matrix).
if [ "$#" -gt 0 ]; then
	packages=("$@")
elif [ -n "${SAMPLE}" ]; then
	case "${SAMPLE}" in
		*[!0-9]*|"") echo "test-all: SAMPLE must be a positive integer (got '${SAMPLE}')" >&2; exit 2 ;;
	esac
	[ "${SAMPLE}" -gt 0 ] || { echo "test-all: SAMPLE must be >= 1" >&2; exit 2; }
	mapfile -t packages < <("${SCRIPT_DIR}/list-packages.sh" | shuf -n "${SAMPLE}")
else
	mapfile -t packages < <("${SCRIPT_DIR}/list-packages.sh")
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
