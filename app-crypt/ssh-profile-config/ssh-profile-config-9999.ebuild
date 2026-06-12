# Copyright 2025-2026 Stefano Balzarotti
# Distributed under the terms of the GNU General Public License v3

EAPI=8

DESCRIPTION="Easy scripts to auto-configure ssh agent and load keys and passwords"
HOMEPAGE="https://github.com/OrbintSoft/ssh-profile-config"
EGIT_REPO_URI="https://github.com/OrbintSoft/ssh-profile-config.git"
LICENSE="MIT"
SLOT="0"
KEYWORDS=""

# Needed to fetch from GitHub
inherit git-r3

src_compile() {
	: # no-op
}

src_install() {
	emake print-paths DESTDIR="${D}" PREFIX="/usr"
	emake install DESTDIR="${D}" PREFIX="/usr"
}
