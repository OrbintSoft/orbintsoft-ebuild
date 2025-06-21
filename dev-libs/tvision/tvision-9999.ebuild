# Copyright 2025
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit cmake git-r3

DESCRIPTION="Turbo Vision - A modern port of Borland's TUI library"
HOMEPAGE="https://github.com/magiblot/tvision"
EGIT_REPO_URI="https://github.com/magiblot/tvision.git"

LICENSE="MIT freed"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE="gpm examples"

DEPEND="
    sys-libs/ncurses:0=[unicode]
    gpm? ( sys-libs/gpm )
"
RDEPEND="${DEPEND}
    x11-misc/xclip
    x11-misc/xsel
    gui-libs/wl-clipboard
"

BDEPEND=">=dev-util/cmake-3.13"

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
    # Install the static lib manually
    dolib.a build/libtvision.a

    # Install headers
    insinto /usr/include
    doins -r include/tvision

    # Backward-compat headers
    doins -r include/tvision/compat

    if use examples; then
        exeinto /usr/share/${PN}/examples
        doexe build/hello build/tvdemo build/tvedit build/tvdir build/mmenu build/palette
    fi

    # Help compiler (optional tool)
    dobin build/tvhc

    dodoc README.md
}
