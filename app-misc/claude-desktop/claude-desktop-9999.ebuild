# Copyright 1999-2026 Gentoo Authors
# Copyright 2026 Stefano Balzarotti
# Distributed under the terms of the GNU General Public License v2

EAPI=9

# Thanks to Anthropic for Claude Desktop and to aaddrick for the Linux
# repackage (https://github.com/aaddrick/claude-desktop-debian).
DESCRIPTION="Claude AI Desktop application (unofficial Linux repackage)"
HOMEPAGE="https://github.com/aaddrick/claude-desktop-debian"

S="${WORKDIR}"

LICENSE="MIT"
SLOT="0"
KEYWORDS=""
IUSE="wayland"
PROPERTIES="live"
RESTRICT="network-sandbox"

RDEPEND="
	dev-libs/nss
	x11-libs/libXScrnSaver
	x11-libs/libXtst
"
BDEPEND="
	app-arch/dpkg
	net-misc/curl
	app-misc/jq
"

src_unpack() {
	local api_url="https://api.github.com/repos/aaddrick/claude-desktop-debian/releases/latest"

	einfo "Querying latest release..."
	local deb_url=$(curl -sL --fail "${api_url}" \
		| jq -r '.assets[] | select(.name | endswith("_amd64.deb")) | .browser_download_url' \
		| head -n1)

	[[ -z "${deb_url}" ]] && die "Could not determine latest .deb URL"
	einfo "Downloading: ${deb_url}"

	local deb_file="${T}/claude-desktop.deb"
	curl -L --fail -o "${deb_file}" "${deb_url}" || die "Download failed"

	dpkg-deb -x "${deb_file}" "${S}" || die "dpkg-deb extraction failed"
}

src_install() {
	[[ -d "${S}/usr" ]] && { cp -r "${S}/usr" "${D}/" || die ; }
	[[ -d "${S}/opt" ]] && { cp -r "${S}/opt" "${D}/" || die ; }

}

pkg_postinst() {
	elog "Claude Desktop installed! Launch it with: claude-desktop"
}
