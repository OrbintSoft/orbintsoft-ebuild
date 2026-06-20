#!/usr/bin/env bash
# Copyright 2026 Stefano Balzarotti
# Distributed under the terms of the GNU General Public License v3
#
# changed-packages.sh — given a list of changed file paths on stdin, print the
# overlay packages whose build could be affected, for the dynamic test matrix.
# Complements scripts/list-packages.sh, which lists *every* package; this narrows
# the CI fan-out to just what a PR touches.
#
# Usage:   git diff --name-only base...HEAD | scripts/changed-packages.sh
#          ... | scripts/changed-packages.sh --json    # compact JSON (CI matrix)
#
# Each changed path is classified as:
#   * category/package/...           -> that package
#   * overlay-semantics infra        -> ALL packages (can change any build):
#         profiles/  metadata/  eclass/
#         (except profiles/categories & profiles/repo_name — overlay metadata that
#          cannot change an existing package's build, so they are ignored: a new
#          category rides along with its new package, which is already selected)
#   * test-harness / CI infra        -> ONE random package: a smoke test that the
#         container test path still works, without the full matrix:
#         scripts/  Makefile  .github/workflows/test.yml
#   * any other .github/workflows/*   -> ignored: a workflow only orchestrates CI
#         and cannot change a package build (test.yml above is the sole build
#         driver). Generic, so new workflows need no allow-list entry.
#   * docs / lint-only / bot config   -> ignored (cannot change a build):
#         *.md  LICENSE  .editorconfig  .gitignore  .gitattributes
#         .yamllint  checkmake.ini  renovate.json  renovate.json5
#         .github/dependabot.yml
#   * anything else (unrecognized)    -> ALL packages (safe default)
#
# When a PR changes both a package and harness infra, the changed package already
# smoke-tests the harness, so the random pick only kicks in for harness-only PRs
# (e.g. Dependabot/Renovate bumping the stage3 digest or an action SHA).
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
test_one=

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
		# Overlay metadata that cannot change an existing package's build: a new
		# category is added together with its new package (already selected above),
		# and repo_name is just the overlay's identity. Ignore (no retest).
		profiles/categories|profiles/repo_name)
			: ;;
		# Overlay-semantics infrastructure -> retest everything (any build).
		profiles/*|metadata/*|eclass/*)
			test_all=1 ;;
		# Test-harness / CI infrastructure -> smoke-test ONE random package:
		# proves the container test path still works without the full matrix.
		# Subsumed when specific packages are already selected. Only test.yml
		# drives the build harness, so only it gets the smoke.
		scripts/*|Makefile|.github/workflows/test.yml)
			test_one=1 ;;
		# Any OTHER workflow only orchestrates CI; it cannot change a package build
		# (test.yml above is the sole build driver, and gets the smoke). Ignore it
		# generically so new workflows are covered without growing an allow-list.
		.github/workflows/*)
			: ;;
		# Docs, lint-only config and bot config -> cannot affect a build, ignore.
		*.md|LICENSE|.editorconfig|.gitignore|.gitattributes|.yamllint|checkmake.ini|renovate.json|renovate.json5|.github/dependabot.yml)
			: ;;
		# Unrecognized -> safe default: retest everything.
		*)
			test_all=1 ;;
	esac
done

if [ -n "${test_all}" ]; then
	packages=("${all_packages[@]}")
elif [ "${#selected[@]}" -gt 0 ]; then
	# Specific packages changed — they also exercise the test harness, so a
	# concurrent harness-infra change (test_one) needs no extra random pick.
	mapfile -t packages < <(printf '%s\n' "${!selected[@]}" | sort -u)
elif [ -n "${test_one}" ] && [ "${#all_packages[@]}" -gt 0 ]; then
	# Harness-only change: one random package, just to confirm CI isn't broken.
	mapfile -t packages < <(printf '%s\n' "${all_packages[@]}" | shuf -n1)
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
