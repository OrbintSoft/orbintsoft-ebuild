# Copyright 1999-2026 Gentoo Authors
# Copyright 2026 Stefano Balzarotti
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit meson

# QA-TEST: binpkg-respect-use image=gentoo/stage3:desktop@sha256:88ea9336c900219b0d783b36fbe391a43d47d7ea7a9e3e78b66f8d4f31ed8547
# Thanks to cboxdoerfer, author of FSearch (https://github.com/cboxdoerfer/fsearch).
DESCRIPTION="A fast file search utility for Unix-like systems"
HOMEPAGE="https://github.com/cboxdoerfer/fsearch"
SRC_URI="https://github.com/cboxdoerfer/fsearch/archive/${PV}.tar.gz -> ${P}.tar.gz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64"

DEPEND="
	dev-libs/glib:2
	dev-libs/icu
	dev-libs/libpcre2
	x11-libs/gtk+:3
"
RDEPEND="${DEPEND}"
BDEPEND="
	virtual/pkgconfig
	dev-util/itstool
	dev-util/glib-utils
"
