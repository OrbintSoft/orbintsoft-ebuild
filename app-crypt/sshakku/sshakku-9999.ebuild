# Copyright 2025-2026 Stefano Balzarotti
# Distributed under the terms of the GNU General Public License v3

EAPI=9

# QA-TEST: source
DESCRIPTION="Tend the SSH agent: lifecycle, health checks, diagnostics, key loading"
HOMEPAGE="https://github.com/OrbintSoft/sshakku"
EGIT_REPO_URI="https://github.com/OrbintSoft/sshakku.git"
LICENSE="EUPL-1.2"
SLOT="0"
KEYWORDS=""

# Needed to fetch from GitHub
inherit git-r3

src_compile() {
	: # no-op
}

src_install() {
	emake print-paths DESTDIR="${D}" PREFIX="/usr"
	emake install DESTDIR="${D}" PREFIX="/usr"
}
