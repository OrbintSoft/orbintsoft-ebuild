# Copyright 2025 Stefano Balzarotti
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DESCRIPTION="Easy scripts to auto-configure ssh agent and load keys and passwords"
HOMEPAGE="https://github.com/OrbintSoft/ssh-profile-config"
EGIT_REPO_URI="https://github.com/OrbintSoft/ssh-profile-config.git"
LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64 ~x86 ~arm ~arm64 ~riscv ~ppc ~ppc64"
IUSE=""

# Needed to fetch from GitHub
inherit git-r3

DEPEND=""
RDEPEND="${DEPEND}"

src_compile() {
    : # no-op
}

src_install() {
   emake print-paths DESTDIR="${D}" PREFIX="/usr"
   emake install DESTDIR="${D}" PREFIX="/usr"
}
