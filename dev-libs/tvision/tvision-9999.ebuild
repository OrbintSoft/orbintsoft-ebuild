# Copyright 1999-2026 Gentoo Authors
# Copyright 2026 Stefano Balzarotti
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit cmake git-r3

# QA-TEST: source
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
# System-clipboard sync execs xsel/xclip (X) or wl-clipboard (Wayland) when those
# are present and gracefully no-ops otherwise; they are optional runtime helpers,
# not dependencies.
RDEPEND="${DEPEND}"

BDEPEND="dev-build/cmake"

src_configure() {
	local mycmakeargs=(
		-DCMAKE_BUILD_TYPE=Release
		-DCMAKE_INSTALL_PREFIX="${EPREFIX}/usr"
		# PIC so the static libtvision.a can be linked into shared consumers
		# (e.g. app-editors/turbo's libturbo-core.so); the default non-PIC build
		# uses local-exec TLS, which ld rejects when making a shared object.
		-DCMAKE_POSITION_INDEPENDENT_CODE=ON
	)
	cmake_src_configure
}

src_compile() {
	cmake_src_compile
}

src_install() {
	cmake_src_install
}
