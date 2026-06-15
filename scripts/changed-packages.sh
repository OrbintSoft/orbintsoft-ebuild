#!/usr/bin/env bash
# Copyright 2026 Stefano Balzarotti
# Distributed under the terms of the GNU General Public License v3
#
# changed-packages.sh — given a list of changed file paths on stdin, print the
# overlay packages whose build could be affected, for the dynamic test matrix
# (PLAN.md Phase 2E / 2.9). Complements scripts/list-packages.sh, which lists
# *every* package; this narrows the CI fan-out to just what a PR touches.
#
# Usage:   git diff --name-only base...HEAD | scripts/changed-packages.sh
#          ... | scripts/changed-packages.sh --json    # compact JSON (CI matrix)
#
# Each changed path is classified as:
#   * category/package/...           -> that package
#   * build-affecting infrastructure -> ALL packages (a fresh full matrix):
#         profiles/  metadata/  eclass/  scripts/  Makefile
#         .github/workflows/test.yml   (the test workflow itself)
#   * docs / lint-only config         -> ignored (cannot change a build):
#         *.md  LICENSE  .editorconfig  .gitignore  .gitattributes
#         .yamllint  checkmake.ini  .github/workflows/lint.yml
#   * anything else (unrecognized)    -> ALL packages (safe default)
#
# Output mirrors list-packages.sh: one "category/package" per line, or a compact
# JSON array with --json. An empty result (only docs/config changed) prints
# nothing / "[]" — the CI matrix then expands to zero jobs.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

format=lines
case "${1:-}" in
	""|--lines) : ;;
	--json) format=json ;;
	*) echo "changed-packages: unknown option '$1' (use --json or --lines)" >&2; exit 2 ;;
esac

# The full package set is both the source of truth for "is this path a package?"
# and the target of the test-all fallbacks.
mapfile -t all_packages < <("${SCRIPT_DIR}/list-packages.sh")
declare -A is_package=()
for pkg in "${all_packages[@]}"; do
	is_package["${pkg}"]=1
done

declare -A selected=()
test_all=

while IFS= read -r file; do
	[ -n "${file}" ] || continue
	file="${file#./}"

	# First two path components -> candidate "category/package".
	rest="${file#*/}"
	if [ "${rest}" != "${file}" ]; then
		pkg="${file%%/*}/${rest%%/*}"
	else
		pkg="${file}"           # top-level file, never a package
	fi

	if [ -n "${is_package[${pkg}]:-}" ]; then
		selected["${pkg}"]=1
		continue
	fi

	# Not inside a known package — classify the path.
	case "${file}" in
		# Build-affecting infrastructure -> retest everything.
		profiles/*|metadata/*|eclass/*|scripts/*|Makefile|.github/workflows/test.yml)
			test_all=1 ;;
		# Docs and lint-only config -> cannot affect a build, ignore.
		*.md|LICENSE|.editorconfig|.gitignore|.gitattributes|.yamllint|checkmake.ini|.github/workflows/lint.yml)
			: ;;
		# Unrecognized -> safe default: retest everything.
		*)
			test_all=1 ;;
	esac
done

if [ -n "${test_all}" ]; then
	packages=("${all_packages[@]}")
elif [ "${#selected[@]}" -gt 0 ]; then
	mapfile -t packages < <(printf '%s\n' "${!selected[@]}" | sort -u)
else
	packages=()
fi

if [ "${format}" = json ]; then
	# Build ["cat/pkg",...] by hand: no jq dependency, and atoms carry no
	# JSON-special characters so plain quoting is safe (see list-packages.sh).
	json="["
	sep=""
	for pkg in ${packages[@]+"${packages[@]}"}; do
		json+="${sep}\"${pkg}\""
		sep=","
	done
	json+="]"
	printf '%s\n' "${json}"
elif [ "${#packages[@]}" -gt 0 ]; then
	printf '%s\n' "${packages[@]}"
fi
