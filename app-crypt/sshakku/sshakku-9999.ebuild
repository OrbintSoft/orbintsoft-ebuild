# Copyright 2025-2026 Stefano Balzarotti
# Distributed under the terms of the GNU General Public License v3

EAPI=9

# QA-TEST: source
DESCRIPTION="Tend the SSH agent: lifecycle, health checks, diagnostics, key loading"
HOMEPAGE="https://github.com/OrbintSoft/sshakku"
EGIT_REPO_URI="https://github.com/OrbintSoft/sshakku.git"
# EUPL-1.2 is sshakku's own licence; BSD covers the vendored golang.org/x/sys.
LICENSE="EUPL-1.2 BSD"
SLOT="0"
KEYWORDS=""

# git-r3 fetches the live source from GitHub; go-module vendors the Go module
# dependencies during src_unpack so the build runs offline in the sandbox.
inherit git-r3 go-module

# go-module already pulls in a baseline Go; go.mod needs at least this toolchain.
BDEPEND+=" >=dev-lang/go-1.25.0"

src_unpack() {
	git-r3_src_unpack
	go-module_live_vendor
}

src_compile() {
	: # no-op
}

src_install() {
	emake print-paths DESTDIR="${D}" PREFIX="/usr"
	emake install DESTDIR="${D}" PREFIX="/usr"
}
