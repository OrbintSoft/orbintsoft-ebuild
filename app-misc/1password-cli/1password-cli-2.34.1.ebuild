# Copyright 1999-2026 Gentoo Authors
# Copyright 2026 Stefano Balzarotti
# Distributed under the terms of the GNU General Public License v2

EAPI=9

# QA-TEST: source
# Thanks to AgileBits, author of 1Password (https://1password.com).
DESCRIPTION="Command-line interface for the 1Password password manager"
HOMEPAGE="https://developer.1password.com/docs/cli/"
SRC_URI="https://cache.agilebits.com/dist/1P/op2/pkg/v${PV}/op_linux_amd64_v${PV}.zip -> ${P}-amd64.zip"

S="${WORKDIR}"

LICENSE="all-rights-reserved"
SLOT="0"
KEYWORDS="~amd64"
RESTRICT="bindist mirror strip test"

RDEPEND="acct-group/onepassword-cli"
BDEPEND="app-arch/unzip"

QA_FLAGS_IGNORED="usr/bin/op"
QA_PREBUILT="usr/bin/op"

src_install() {
	dobin op

	# op refuses to talk to the desktop app unless its own binary is setgid to
	# this group; the app checks the caller's gid to authenticate the CLI.
	chgrp onepassword-cli "${ED}/usr/bin/op" || die
	fperms g+s /usr/bin/op
}
