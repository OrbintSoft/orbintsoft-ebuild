# Copyright 1999-2026 Gentoo Authors
# Copyright 2026 Stefano Balzarotti
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit meson git-r3

# Thanks to thkukuk, author of pamtester (https://github.com/thkukuk/pamtester).
DESCRIPTION="Non-interactive PAM testing tool"
HOMEPAGE="https://github.com/thkukuk/pamtester"
EGIT_REPO_URI="https://github.com/thkukuk/pamtester.git"

LICENSE="BSD"
SLOT="0"
KEYWORDS="amd64"
IUSE=""

DEPEND="
	sys-libs/pam
"
RDEPEND="${DEPEND}"
BDEPEND="
	virtual/pkgconfig
	dev-libs/libxslt
	app-text/docbook-xsl-ns-stylesheets
"

src_configure() {
	local emesonargs=(
		# Build the man page from DocBook rather than relying on
		# meson's automagic xsltproc detection.
		-Dman=enabled
	)
	meson_src_configure
}
