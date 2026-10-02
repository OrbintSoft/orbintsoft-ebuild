# Copyright 2026 Stefano Balzarotti
# Distributed under the terms of the GNU General Public License v3

EAPI=9

# QA-TEST: source
# Thanks to Anthropic, author of Claude Science (https://claude.com/product/claude-science).
DESCRIPTION="Claude Science, Anthropic's AI workbench for scientific research"
HOMEPAGE="https://claude.com/product/claude-science"
SRC_URI="https://downloads.claude.ai/claude-science/${PV}/linux-x64 -> ${P}-linux-x64"

S="${WORKDIR}"

LICENSE="all-rights-reserved"
SLOT="0"
KEYWORDS="~amd64"
RESTRICT="bindist mirror strip test"

# The analysis sandbox needs bwrap --disable-userns (bubblewrap 0.8.0+) and
# socat for its network bridge.
RDEPEND="
	>=sys-apps/bubblewrap-0.8.0
	net-misc/socat
"

QA_FLAGS_IGNORED="usr/bin/claude-science"
QA_PREBUILT="usr/bin/claude-science"

src_unpack() {
	# The upstream download is a bare executable, not an archive.
	cp "${DISTDIR}/${P}-linux-x64" "${S}/claude-science" || die
}

src_install() {
	dobin claude-science
}

pkg_postinst() {
	elog "Start Claude Science with: claude-science serve"
	elog "It prints a local URL and opens the app in your browser."
	elog
	elog "Updates are managed by Portage. To stop the app from updating itself,"
	elog "add this to ~/.claude-science/config.toml:"
	elog "  [update]"
	elog "  auto_update = false"
}
