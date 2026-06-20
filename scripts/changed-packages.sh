#!/usr/bin/env bash
# Copyright 2026 Stefano Balzarotti
# Distributed under the terms of the GNU General Public License v3
#
# changed-packages.sh — given a list of changed file paths on stdin, print the
# overlay packages whose build a change could affect, for the dynamic test
# matrix. Complements scripts/list-packages.sh (which lists *every* package);
# this narrows the CI fan-out to just what a PR actually touches.
#
# Usage:   git diff --name-only base...HEAD | scripts/changed-packages.sh
#          ... | scripts/changed-packages.sh --json    # compact JSON (CI matrix)
#
# Classification, designed so a forgotten or brand-new kind of file can never run
# the whole suite — its worst case is a single smoke-test:
#   * category/package/...          -> that package (matched against the real list)
#   * eclass/, profiles/, metadata/ -> overlay-wide build semantics; and
#     scripts/, Makefile, .github/workflows/test.yml -> the test harness itself;
#     and anything unrecognized -> smoke-test ONE random package
#   * docs, repo/editor/lint/bot config, other .github/ files -> ignored
#     (cannot affect a build; CI still lints them)
#
# The whole suite is NEVER run from here. The ignore list is only an optimization
# (so docs/config changes skip even the smoke-test); if it ever misses a file,
# that file falls through to a harmless one-package smoke-test, not the full matrix.
#
# Output mirrors list-packages.sh: one "category/package" per line, or a compact
# JSON array with --json. An empty result (only ignored paths changed) prints
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
# and the pool the smoke-test picks from.
mapfile -t all_packages < <("${SCRIPT_DIR}/list-packages.sh")
declare -A is_package=()
for pkg in "${all_packages[@]}"; do
	is_package["${pkg}"]=1
done

declare -A selected=()
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

	# Not inside a known package. Smoke-test one package for anything that could
	# affect a build (overlay semantics) or that drives the harness, plus the
	# unrecognized default — never the whole suite. Known build-irrelevant files
	# are ignored so they don't even trigger the smoke.
	case "${file}" in
		# The container-test driver itself -> smoke (listed before the .github
		# ignore below, which would otherwise swallow it).
		.github/workflows/test.yml)
			test_one=1 ;;
		# Overlay build semantics and the test harness/tooling -> smoke.
		eclass/*|profiles/*|metadata/*|scripts/*|Makefile)
			test_one=1 ;;
		# Cannot affect a build -> ignore (CI still lints them): docs, repo/editor
		# config, lint/bot config, and every other file under .github/ (other
		# workflows, FUNDING.yml, dependabot.yml, issue templates, ...).
		*.md|LICENSE|.editorconfig|.gitignore|.gitattributes|.yamllint|checkmake.ini|renovate.json|renovate.json5|.github/*)
			: ;;
		# Anything unrecognized -> one smoke-test package, never the whole suite.
		*)
			test_one=1 ;;
	esac
done

if [ "${#selected[@]}" -gt 0 ]; then
	# Specific packages changed — they also exercise the test harness, so a
	# concurrent harness/infra change needs no extra smoke pick.
	mapfile -t packages < <(printf '%s\n' "${!selected[@]}" | sort -u)
elif [ -n "${test_one}" ] && [ "${#all_packages[@]}" -gt 0 ]; then
	# Infra-only change: one random package, just to confirm CI isn't broken.
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
