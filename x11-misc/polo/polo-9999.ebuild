# Copyright 2026 Stefano Balzarotti
# Distributed under the terms of the GNU General Public License v3

EAPI=8

inherit git-r3 vala xdg

# QA-TEST: source
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

DEPEND="${RDEPEND}"

# Build-time tools (native): the Vala compiler, xgettext and pkg-config.
BDEPEND="
	$(vala_depend)
	sys-devel/gettext
	virtual/pkgconfig
"

src_configure() {
	vala_setup
	# Upstream's hand-written makefile invokes the compiler by its bare name
	# `valac` (both in compile recipes and in a parse-time `valac --version`
	# probe the install target also triggers), but Gentoo installs only the
	# slotted valac-${version} (the bare symlink is eselect-vala's job). Expose
	# the version vala_setup picked under that name; both emakes prepend it to PATH.
	mkdir -p "${T}/vala-bin" || die
	ln -sf "${VALAC}" "${T}/vala-bin/valac" || die
}

src_compile() {
	PATH="${T}/vala-bin:${PATH}" emake
}

src_install() {
	PATH="${T}/vala-bin:${PATH}" emake DESTDIR="${D}" install

	# Upstream installs the AppStream metadata under the legacy
	# /usr/share/appdata; relocate it to the modern /usr/share/metainfo.
	if [[ -d "${ED}/usr/share/appdata" ]]; then
		dodir /usr/share/metainfo
		mv "${ED}"/usr/share/appdata/*.xml "${ED}"/usr/share/metainfo/ || die
		rmdir "${ED}/usr/share/appdata" || die
	fi

	# Upstream creates an empty /var/log/polo; keep it so Portage does not
	# prune the empty directory (QA: empty directory in /var).
	keepdir /var/log/polo
}
