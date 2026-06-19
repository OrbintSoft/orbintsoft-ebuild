# Copyright 2026 Stefano Balzarotti
# Distributed under the terms of the GNU General Public License v3

EAPI=9

inherit go-module

DESCRIPTION="A tool to create backups compatible with redo"
HOMEPAGE="https://github.com/OrbintSoft/redo-backups"
SRC_URI="https://github.com/OrbintSoft/redo-backups/archive/refs/tags/v${PV}.tar.gz -> ${P}.tar.gz"

LICENSE="EUPL-1.2"
SLOT="0"
KEYWORDS="~amd64"

# Must match go.mod's go directive (go-module QA dies on mismatch under EAPI 9).
BDEPEND=">=dev-lang/go-1.26:="

src_compile() {
	ego build ./cmd/redo-backup
}

src_install() {
	dobin redo-backup
	einstalldocs
}
