# Copyright 2025
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit git-r3 cmake

DESCRIPTION="Turbo Vision 2.0 - A modern port of Borland's text-based UI library"
HOMEPAGE="https://github.com/magiblot/tvision"
EGIT_REPO_URI="https://github.com/magiblot/tvision.git"

LICENSE="MIT freed"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE=""

DEPEND=">=dev-util/cmake-3"
RDEPEND="${DEPEND}"

src_configure() {
    cmake_src_configure
}

src_compile() {
    cmake_src_compile
}

src_install() {
    cmake_src_install
}
