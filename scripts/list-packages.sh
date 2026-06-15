#!/usr/bin/env bash
# Copyright 2026 Stefano Balzarotti
# Distributed under the terms of the GNU General Public License v3
#
# list-packages.sh — print every package in this overlay: each cat/pkg directory
# (depth 3) that holds at least one *.ebuild. Single source of truth for the
# package list, shared by scripts/test-all.sh (the local suite) and the test CI
# matrix (PLAN.md Phase 2D / 2.8).
#
# Usage:   scripts/list-packages.sh           # one "category/package" per line
#          scripts/list-packages.sh --json    # compact JSON array (CI matrix)
#
# Atoms are plain category/name (no quotes, spaces or backslashes), so the JSON
# needs no escaping — the workflow can fromJSON() it without depending on jq.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OVERLAY_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

format=lines
case "${1:-}" in
	""|--lines) : ;;
	--json) format=json ;;
	*) echo "list-packages: unknown option '$1' (use --json or --lines)" >&2; exit 2 ;;
esac

cd "${OVERLAY_ROOT}"
mapfile -t packages < <(find . -mindepth 3 -maxdepth 3 -name '*.ebuild' -printf '%h\n' | sed 's,^\./,,' | sort -u)
[ "${#packages[@]}" -gt 0 ] || { echo "list-packages: no packages found" >&2; exit 1; }

if [ "${format}" = json ]; then
	# Build ["cat/pkg","cat/pkg",...] by hand: no jq dependency, and atoms carry
	# no JSON-special characters so plain quoting is safe.
	json="["
	sep=""
	for pkg in "${packages[@]}"; do
		json+="${sep}\"${pkg}\""
		sep=","
	done
	json+="]"
	printf '%s\n' "${json}"
else
	printf '%s\n' "${packages[@]}"
fi
