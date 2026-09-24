# Copyright 1999-2026 Gentoo Authors
# Copyright 2026 Stefano Balzarotti
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit desktop optfeature xdg

# QA-TEST: binpkg
# Thanks to AgileBits, author of 1Password (https://1password.com).
DESCRIPTION="Password manager and secure digital wallet"
HOMEPAGE="https://1password.com"
SRC_URI="https://downloads.1password.com/linux/tar/stable/x86_64/${P}.x64.tar.gz -> ${P}.tar.gz"

S="${WORKDIR}"

LICENSE="all-rights-reserved"
SLOT="0"
KEYWORDS="~amd64"
RESTRICT="bindist mirror strip"

DEPEND="
	x11-misc/xdg-utils
	acct-group/1password
"
RDEPEND="
	${DEPEND}
	app-accessibility/at-spi2-core:2
	dev-libs/expat
	dev-libs/glib:2
	dev-libs/nspr
	dev-libs/nss
	media-libs/alsa-lib
	media-libs/mesa
	net-print/cups
	sys-apps/dbus
	x11-libs/cairo
	x11-libs/gtk+:3
	x11-libs/libX11
	x11-libs/libXcomposite
	x11-libs/libXdamage
	x11-libs/libXext
	x11-libs/libXfixes
	x11-libs/libXrandr
	x11-libs/libxcb
	x11-libs/libxkbcommon
	x11-libs/pango
	virtual/zlib
"

QA_PREBUILT="/opt/1Password/*"

src_install() {
	cd "${S}/${PN}"-* || die

	dodir /opt/1Password
	cp -ar ./* "${ED}/opt/1Password/" || die "Install failed!"

	# The polkit policy template lists the (first 10) human users allowed to
	# unlock the vault via biometrics; fill it in from the local passwd db.
	dodir /usr/share/polkit-1/actions
	local policy_owners
	policy_owners="$(cut -d: -f1,3 /etc/passwd \
		| grep -E ':[0-9]{4}$' \
		| cut -d: -f1 \
		| head -n 10 \
		| sed 's/^/unix-user:/' \
		| tr '\n' ' ')"
	sed -e "s/\${POLICY_OWNERS}/${policy_owners}/" \
		"${ED}/opt/1Password/com.1password.1Password.policy.tpl" \
		> "${ED}/usr/share/polkit-1/actions/com.1password.1Password.policy" ||
		die "Failed to create policy file"

	fperms 644 /usr/share/polkit-1/actions/com.1password.1Password.policy

	dosym -r /opt/1Password/1password /usr/bin/1password
	dosym -r /opt/1Password/op-ssh-sign /usr/bin/op-ssh-sign

	domenu resources/1password.desktop
	local size
	for size in 32 64 256 512; do
		doicon -s ${size} resources/icons/hicolor/${size}x${size}/apps/1password.png
	done

	dodoc "${ED}/opt/1Password/resources/custom_allowed_browsers"

	rm "${ED}/opt/1Password/com.1password.1Password.policy.tpl" || die
	rm "${ED}/opt/1Password/resources/"{1password.desktop,custom_allowed_browsers} || die
	rm -r "${ED}/opt/1Password/resources/icons" || die

	# chrome-sandbox requires the setuid bit to be specifically set.
	# See https://github.com/electron/electron/issues/17972
	fperms 4755 /opt/1Password/chrome-sandbox

	# No extra permissions for the binary; hardens it against environmental
	# tampering by restricting it to the 1password group.
	chgrp 1password "${ED}/opt/1Password/1Password-BrowserSupport" || die
	fperms g+s /opt/1Password/1Password-BrowserSupport
}

pkg_postinst() {
	xdg_pkg_postinst

	optfeature "1Password CLI" app-misc/1password-cli
}
