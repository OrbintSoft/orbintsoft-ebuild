# Copyright 1999-2026 Gentoo Authors
# Copyright 2026 Stefano Balzarotti
# Distributed under the terms of the GNU General Public License v2

EAPI=9

inherit acct-group

# QA-TEST: source
# See acct-group/1password for why this is a fixed id >= 1000 rather than
# the usual auto-allocated system range.
ACCT_GROUP_ID=1007
