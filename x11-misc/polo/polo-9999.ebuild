# Copyright 2026 Stefano Balzarotti
# Distributed under the terms of the GNU General Public License v3

EAPI=8

inherit git-r3 autotools xdg

# Thanks to teejee2008 (Tony George), author of the original Polo File Manager;
# maintained here as the OrbintSoft fork (https://github.com/OrbintSoft/polo).
DESCRIPTION="Polo File Manager (Vala/GTK)"
HOMEPAGE="https://github.com/OrbintSoft/polo"
EGIT_REPO_URI="https://github.com/OrbintSoft/polo.git"

LICENSE="GPL-3"
SLOT="0"
KEYWORDS="amd64"
IUSE=""

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
	x11-misc/shared-mime-info
	dev-util/desktop-file-utils
"

# Build-time dependencies
DEPEND="${RDEPEND}
	sys-devel/gettext
	dev-util/intltool
	dev-lang/vala
"

# Prepare phase: regenerate configure script if needed
src_prepare() {
	default
}

# Configure phase
src_configure() {
	emake
}

# Compile phase
src_compile() {
	emake
}

# Install phase
src_install() {
	emake DESTDIR="${D}" install
}
