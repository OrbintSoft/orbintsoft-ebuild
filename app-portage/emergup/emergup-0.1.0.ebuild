# Copyright 2026 Stefano Balzarotti
# Distributed under the terms of the GNU General Public License v3

EAPI=9

inherit go-module optfeature

# QA-TEST: binpkg
DESCRIPTION="Keeps a Gentoo system up to date with one command"
HOMEPAGE="https://github.com/OrbintSoft/emergup"
# The vendored Go modules come with each release, so the build needs no
# network.
SRC_URI="
	https://github.com/OrbintSoft/emergup/archive/refs/tags/v${PV}.tar.gz -> ${P}.tar.gz
	https://github.com/OrbintSoft/emergup/releases/download/v${PV}/${P}-vendor.tar.xz
"

# GPL-3+ is emergup's own licence; MIT covers the vendored go-toml, BSD the
# vendored golang.org/x/sys and golang.org/x/term.
LICENSE="GPL-3+ BSD MIT"
SLOT="0"
KEYWORDS="~amd64"

# emergup drives Portage's own tools: emerge, portageq, dispatch-conf, and
# find for the pending configuration-file updates.
RDEPEND="
	sys-apps/findutils
	sys-apps/portage
"
# Must match go.mod's go directive as it is written, 1.26.0 (go-module QA
# dies on a mismatch under EAPI 9).
BDEPEND=">=dev-lang/go-1.26.0:="

src_compile() {
	# GOTOOLCHAIN=local builds with the installed Go instead of downloading
	# the toolchain go.mod names.
	emake GOTOOLCHAIN=local VERSION="${PV}" build
}

src_test() {
	emake GOTOOLCHAIN=local test
}

src_install() {
	# `install` depends on the phony `build`, so it builds again: VERSION must
	# be repeated, or `emergup version` would not report the release.
	emake GOTOOLCHAIN=local VERSION="${PV}" PREFIX="${EPREFIX}/usr" DESTDIR="${D}" install
	dodoc README.md docs/FEATURES.md

	# Every setting of the example is commented out with its default, so it
	# documents the configuration without changing it.
	insinto /etc/emergup
	doins examples/etc/emergup/config.toml
	keepdir /etc/emergup/config.d
}

pkg_postinst() {
	optfeature "running the commands that need root as an ordinary user" app-admin/sudo app-admin/doas
	optfeature "the smart mode of the live-package rebuild" app-portage/smart-live-rebuild
}
