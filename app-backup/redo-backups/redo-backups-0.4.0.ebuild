# Copyright 2026 Stefano Balzarotti
# Distributed under the terms of the GNU General Public License v3

EAPI=9

inherit go-module

# QA-TEST: binpkg
DESCRIPTION="A tool to create backups compatible with redo"
HOMEPAGE="https://github.com/OrbintSoft/redo-backups"
SRC_URI="https://github.com/OrbintSoft/redo-backups/archive/refs/tags/v${PV}.tar.gz -> ${P}.tar.gz"

LICENSE="EUPL-1.2"
SLOT="0"
KEYWORDS="~amd64"

# redo-backup drives partclone to clone/restore filesystems.
RDEPEND="sys-block/partclone"

# Must match go.mod's go directive (go-module QA dies on mismatch under EAPI 9).
BDEPEND=">=dev-lang/go-1.26:="

src_compile() {
	emake VERSION="v${PV}" build
}

src_install() {
	# `install` depends on the phony `build`, so it recompiles: VERSION must be
	# repeated here or the rebuild overwrites the binary with an unversioned one
	# and `redo-backup version` reports the 0.0.0-dev placeholder.
	emake VERSION="v${PV}" PREFIX="/usr" docdir="/usr/share/doc/${PF}" DESTDIR="${D}" install
}
