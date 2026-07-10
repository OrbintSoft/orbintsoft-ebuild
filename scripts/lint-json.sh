#!/usr/bin/env bash
# Copyright 2026 Stefano Balzarotti
# Distributed under the terms of the GNU General Public License v3
#
# lint-json.sh — check that every given *.json file is well-formed.
#
# Usage:   scripts/lint-json.sh [file.json ...]     # no files => nothing to do
#
# Parsing is done by python3's json.tool, already a de-facto dependency of the
# toolchain (pkgcheck, pkgdev and yamllint are all Python) and present on stock
# CI runners, so this adds nothing to install and nothing to keep bumped.
#
# Syntax only: no schema is checked. livecheck.json is the only *.json the
# overlay ships and livecheck publishes no schema for it. JSON5 (renovate.json5)
# is a different language — json.tool rejects its comments — and has its own
# validator in `make lint-renovate`; callers must not pass it here.

set -euo pipefail

PYTHON="${PYTHON:-python3}"

if [ "$#" -eq 0 ]; then
	echo "no json sources to check"
	exit 0
fi

status=0
for file; do
	if ! "${PYTHON}" -m json.tool "${file}" >/dev/null; then
		echo "lint-json: ${file}: not well-formed" >&2
		status=1
	fi
done

exit "${status}"
