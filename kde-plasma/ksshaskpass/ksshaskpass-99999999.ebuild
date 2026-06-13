# Copyright 2026 Stefano Balzarotti
# Distributed under the terms of the GNU General Public License v3

EAPI=9

DESCRIPTION="Dummy package to satisfy dependencies without installing anything"
HOMEPAGE="https://github.com/OrbintSoft/orbintsoft-ebuild"
S="${WORKDIR}"
LICENSE="metapackage"
SLOT="6"
KEYWORDS=""

src_install() {
	einfo "Nothing to install."
}
