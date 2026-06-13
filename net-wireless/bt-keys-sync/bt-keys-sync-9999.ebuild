# Copyright 1999-2026 Gentoo Authors
# Copyright 2026 Stefano Balzarotti
# Distributed under the terms of the GNU General Public License v2

EAPI=9

inherit git-r3

# Thanks to KeyofBlueS, author of bt-keys-sync (https://github.com/KeyofBlueS/bt-keys-sync).
DESCRIPTION="Sync Bluetooth pairing keys between Windows and Linux"
HOMEPAGE="https://github.com/KeyofBlueS/bt-keys-sync"
EGIT_REPO_URI="https://github.com/KeyofBlueS/bt-keys-sync.git"
EGIT_BRANCH="main"

LICENSE="GPL-3"
SLOT="0"
KEYWORDS=""
IUSE="+openrc"

RDEPEND="
	app-crypt/chntpw
	net-wireless/bluez
	sys-apps/util-linux
	sys-apps/coreutils
	sys-apps/grep
	sys-apps/sed
	app-shells/bash
"

src_install() {
	dobin bt-keys-sync.sh

	# Symlink without .sh suffix for convenience
	dosym bt-keys-sync.sh /usr/bin/bt-keys-sync

	dodoc README.md

	if use openrc; then
		newinitd "${FILESDIR}/bt-keys-sync.initd" bt-keys-sync
		newconfd "${FILESDIR}/bt-keys-sync.confd" bt-keys-sync
	fi
}

pkg_postinst() {
	elog ""
	elog "bt-keys-sync requires a Windows partition mounted somewhere"
	elog "(default search path: /mnt and /media)."
	elog ""
	elog "Typical workflow:"
	elog "  1. Pair the Bluetooth device once in Linux"
	elog "  2. Reboot into Windows and re-pair the same device"
	elog "  3. Shut down Windows (with Fast Startup disabled: powercfg /h off)"
	elog "  4. Boot Linux and run:  sudo bt-keys-sync --windows-keys"
	elog ""
	if use openrc; then
		elog "OpenRC service installed. To enable automatic sync at boot:"
		elog "  edit /etc/conf.d/bt-keys-sync (set WINDOWS_MOUNT)"
		elog "  rc-update add bt-keys-sync boot"
		elog ""
	fi
}
