# Copyright 2026 Stefano Balzarotti
# Distributed under the terms of the GNU General Public License v3

EAPI=8

inherit cmake git-r3

# QA-TEST: source
# Thanks to magiblot, author of Turbo (https://github.com/magiblot/turbo).
DESCRIPTION="An experimental text editor based on Scintilla and Turbo Vision"
HOMEPAGE="https://github.com/magiblot/turbo"
EGIT_REPO_URI="https://github.com/magiblot/turbo.git"
# Build against the overlay's dev-libs/tvision (TURBO_USE_SYSTEM_TVISION); only the
# fmt submodule is needed (scintilla is vendored in source/scintilla).
EGIT_SUBMODULES=( deps/fmt )

LICENSE="MIT HPND"
SLOT="0"
KEYWORDS=""

# libmagic (sys-apps/file, in @system) is auto-detected by turbo's CMake and
# always linked; upstream offers no switch, so it is neither a USE flag nor an
# explicit dependency.
DEPEND="dev-libs/tvision"
RDEPEND="${DEPEND}"
BDEPEND="dev-build/cmake"

src_configure() {
	local mycmakeargs=(
		-DTURBO_USE_SYSTEM_TVISION=ON
		-DTURBO_BUILD_APP=ON
		-DTURBO_BUILD_TESTS=OFF
		-DTURBO_BUILD_EXAMPLES=OFF
		# turbo-core is a shared lib; its vendored scintilla/scilexers OBJECT
		# libraries don't inherit that, so force PIC globally or ld rejects their
		# non-PIC relocations when linking libturbo-core.so.
		-DCMAKE_POSITION_INDEPENDENT_CODE=ON
	)
	cmake_src_configure
}
