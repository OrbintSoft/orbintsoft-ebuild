# Copyright 1999-2026 Gentoo Authors
# Copyright 2026 Stefano Balzarotti
# Distributed under the terms of the GNU General Public License v2

EAPI=9

inherit acct-group

# QA-TEST: source
# 1Password's own Linux binaries refuse to trust a setgid helper whose group
# id is below 1000 (undocumented upstream behaviour, confirmed against the
# officially packaged .deb/.rpm groups and reported by users of other
# distributions hitting the same default system-range allocation): a fixed
# id is used instead of the usual auto-allocated system range.
ACCT_GROUP_ID=1006
