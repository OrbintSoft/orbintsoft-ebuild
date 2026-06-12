# Copyright 1999-2026 Gentoo Authors
# Copyright 2026 Stefano Balzarotti
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit meson git-r3

# Thanks to cboxdoerfer, author of FSearch (https://github.com/cboxdoerfer/fsearch).
DESCRIPTION="A fast file search utility for Unix-like systems"
HOMEPAGE="https://github.com/cboxdoerfer/fsearch"
EGIT_REPO_URI="https://github.com/cboxdoerfer/fsearch.git"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="amd64"
IUSE=""

DEPEND="
    dev-libs/glib:2
    x11-libs/gtk+:3
    dev-libs/libpcre2
"
RDEPEND="${DEPEND}"
BDEPEND="virtual/pkgconfig"

src_unpack() {
    git-r3_src_unpack
    cd "${S}" || die

    einfo "Fetching tags..."
    git fetch --tags || die
    latest_tag="$(git describe --tags "$(git rev-list --tags --max-count=1)")" || die
    einfo "Checking out latest tag: ${latest_tag}"
    git checkout "${latest_tag}" || die
}

src_configure() {
    meson_src_configure
}

src_compile() {
    meson_src_compile
}

src_install() {
    meson_src_install
}
