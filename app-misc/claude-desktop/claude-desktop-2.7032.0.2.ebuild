# Copyright 2026 Stefano Balzarotti
# Distributed under the terms of the GNU General Public License v3

EAPI=9

# patrickjaja re-releases the same Claude version with an incrementing
# downstream packaging revision: tag v<ver> is revision 1, v<ver>-<N> is
# revision N. livecheck.json folds the revision into a fourth version component
# (v2.7032.0-2 -> 2.7032.0.2), so bumps pick up re-releases too.
if [[ $(ver_cut 4) ]]; then
	CLAUDE_PV=$(ver_cut 1-3)
	CLAUDE_REL=$(ver_cut 4)
	CLAUDE_TAG="v${CLAUDE_PV}-${CLAUDE_REL}"
else
	CLAUDE_PV=${PV}
	CLAUDE_REL=1
	CLAUDE_TAG="v${PV}"
fi

# QA-TEST: binpkg-respect-use image=gentoo/stage3:desktop@sha256:aefbb8e743dda46bd55f400aba470019b4203e09a57a78f8fce4ab007bd8c8ac
# Thanks to Anthropic for Claude Desktop and to patrickjaja for the Linux
# repackage (https://github.com/patrickjaja/claude-desktop-extra).
DESCRIPTION="Claude AI Desktop application (unofficial Linux repackage)"
HOMEPAGE="https://github.com/patrickjaja/claude-desktop-extra"
SRC_URI="
	https://github.com/patrickjaja/claude-desktop-extra/releases/download/${CLAUDE_TAG}/claude-desktop-extra_${CLAUDE_PV}-${CLAUDE_REL}_amd64.deb
		-> ${P}.deb
"

S="${WORKDIR}"

# Claude Desktop itself is proprietary Anthropic software; only patrickjaja's
# packaging scripts are MIT. The bundle installed here is the proprietary app.
LICENSE="all-rights-reserved"
SLOT="0"
KEYWORDS="~amd64"
RESTRICT="bindist mirror strip"

# libcap-ng and libseccomp are linked by the bundled virtiofsd (Cowork VM);
# libsecret is dlopened for keyring credential storage.
RDEPEND="
	app-accessibility/at-spi2-core
	app-crypt/libsecret
	dev-libs/nss
	media-libs/alsa-lib
	media-libs/mesa
	sys-apps/xdg-desktop-portal
	sys-libs/libcap-ng
	sys-libs/libseccomp
	x11-libs/gtk+:3
	x11-libs/libdrm
	x11-libs/libXScrnSaver
	x11-libs/libXtst
	x11-libs/libnotify
	x11-misc/xdg-utils
"
BDEPEND="app-arch/dpkg"

QA_PREBUILT="*"

src_unpack() {
	# The .deb's inner data.tar is zstd-compressed; dpkg-deb extracts it
	# directly (portage's unpack does not always cover data.tar.zst).
	dpkg-deb -x "${DISTDIR}/${P}.deb" "${S}" || die
}

src_install() {
	# The repackage already lays out a complete /usr tree: the launcher in
	# usr/bin, the app in usr/lib, the .desktop file and hicolor icon in
	# usr/share. Install it verbatim, preserving permissions.
	cp -a "${S}/usr" "${ED}/" || die
	mv "${ED}/usr/share/doc/claude-desktop-extra" "${ED}/usr/share/doc/${PF}" || die
}

pkg_postinst() {
	elog "Launch Claude Desktop from your application menu, or run: claude-desktop"
	elog "The launcher honours CLAUDE_* environment variables (Wayland, GPU,"
	elog "titlebar); see the script at /usr/bin/claude-desktop for details."
}
