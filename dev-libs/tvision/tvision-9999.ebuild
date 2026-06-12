# Copyright 1999-2026 Gentoo Authors
# Copyright 2026 Stefano Balzarotti
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit cmake git-r3

# Thanks to magiblot, author of Turbo Vision (https://github.com/magiblot/tvision).
DESCRIPTION="Turbo Vision - A modern port of Borland's TUI library"
HOMEPAGE="https://github.com/magiblot/tvision"
EGIT_REPO_URI="https://github.com/magiblot/tvision.git"

LICENSE="MIT freedist"
SLOT="0"
KEYWORDS=""
IUSE="gpm examples"

DEPEND="
	sys-libs/ncurses:0
	gpm? ( sys-libs/gpm )
"
RDEPEND="${DEPEND}
	x11-misc/xclip
	x11-misc/xsel
	gui-apps/wl-clipboard
"

BDEPEND="dev-build/cmake"

src_configure() {
	local mycmakeargs=(
		-DCMAKE_BUILD_TYPE=Release
		-DCMAKE_INSTALL_PREFIX="${EPREFIX}/usr"
	)
	cmake_src_configure
}

src_compile() {
	cmake_src_compile
}

src_install() {
	cmake_src_install
}
