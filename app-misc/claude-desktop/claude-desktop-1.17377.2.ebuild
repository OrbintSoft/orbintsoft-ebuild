# Copyright 2026 Stefano Balzarotti
# Distributed under the terms of the GNU General Public License v3

EAPI=9

# patrickjaja re-releases the same Claude version with an incrementing
# downstream packaging revision (the -N suffix on the release tag). The bump
# bot tracks the Claude version (PV); bump this by hand when only -N changes.
CLAUDE_PR="2"

# QA-TEST: binpkg
# Thanks to Anthropic for Claude Desktop and to patrickjaja for the Linux
# repackage (https://github.com/patrickjaja/claude-desktop-bin).
DESCRIPTION="Claude AI Desktop application (unofficial Linux repackage)"
HOMEPAGE="https://github.com/patrickjaja/claude-desktop-bin"
SRC_URI="
	https://github.com/patrickjaja/claude-desktop-bin/releases/download/v${PV}-${CLAUDE_PR}/claude-desktop-bin_${PV}-${CLAUDE_PR}_amd64.deb
		-> ${P}-${CLAUDE_PR}.deb
"

S="${WORKDIR}"

# Claude Desktop itself is proprietary Anthropic software; only patrickjaja's
# packaging scripts are MIT. The bundle installed here is the proprietary app.
LICENSE="all-rights-reserved"
SLOT="0"
KEYWORDS="~amd64"
RESTRICT="bindist mirror strip"

RDEPEND="
	app-accessibility/at-spi2-core
	dev-libs/nss
	media-libs/alsa-lib
	media-libs/mesa
	x11-libs/gtk+:3
	x11-libs/libdrm
	x11-libs/libXScrnSaver
	x11-libs/libXtst
	x11-libs/libnotify
"
BDEPEND="app-arch/dpkg"

QA_PREBUILT="*"

src_unpack() {
	# The .deb's inner data.tar is zstd-compressed; dpkg-deb extracts it
	# directly (portage's unpack does not always cover data.tar.zst).
	dpkg-deb -x "${DISTDIR}/${P}-${CLAUDE_PR}.deb" "${S}" || die
}

src_install() {
	# The repackage already lays out a complete /usr tree: the launcher in
	# usr/bin, the app in usr/lib, the .desktop file and hicolor icon in
	# usr/share. Install it verbatim, preserving permissions.
	cp -a "${S}/usr" "${ED}/" || die
}

pkg_postinst() {
	elog "Launch Claude Desktop from your application menu, or run: claude-desktop"
	elog "The launcher honours CLAUDE_* environment variables (Wayland, GPU,"
	elog "titlebar); see the script at /usr/bin/claude-desktop for details."
}
