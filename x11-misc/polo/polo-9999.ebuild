# Copyright 2026 Stefano Balzarotti
# Distributed under the terms of the GNU General Public License v3

EAPI=8

inherit git-r3 xdg

# Thanks to teejee2008 (Tony George), author of the original Polo File Manager;
# maintained here as the OrbintSoft fork (https://github.com/OrbintSoft/polo).
DESCRIPTION="Polo File Manager (Vala/GTK)"
HOMEPAGE="https://github.com/OrbintSoft/polo"
EGIT_REPO_URI="https://github.com/OrbintSoft/polo.git"

LICENSE="GPL-3"
SLOT="0"
KEYWORDS=""

# Runtime dependencies
RDEPEND="
	dev-libs/glib:2
	dev-libs/json-glib
	dev-libs/libgee
	dev-libs/libxml2
	dev-libs/libxslt
	sys-apps/util-linux
	sys-libs/ncurses
	x11-libs/gtk+:3
	x11-libs/gdk-pixbuf:2
	x11-libs/pango
	x11-libs/cairo
	x11-libs/vte:2.91
	x11-misc/shared-mime-info
	dev-util/desktop-file-utils
"

# Build-time dependencies
DEPEND="${RDEPEND}
	dev-lang/vala
	sys-devel/gettext
	virtual/pkgconfig
"

src_compile() {
	emake
}

src_install() {
	emake DESTDIR="${D}" install
}
