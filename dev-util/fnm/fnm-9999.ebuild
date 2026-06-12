# Copyright 2026 Stefano Balzarotti
# Distributed under the terms of the GNU General Public License v3

EAPI=8

inherit cargo git-r3

# Thanks to Schniz (Gal Schlezinger), author of fnm (https://github.com/Schniz/fnm).
DESCRIPTION="Fast and simple Node.js version manager, built in Rust"
HOMEPAGE="https://github.com/Schniz/fnm"
EGIT_REPO_URI="https://github.com/Schniz/fnm.git"

LICENSE="GPL-3"
SLOT="0"
KEYWORDS="amd64"

# rust does not honor *FLAGS from make.conf; silence the portage QA notice
QA_FLAGS_IGNORED="usr/bin/fnm"

src_unpack() {
	git-r3_src_unpack
	cargo_live_src_unpack
}
