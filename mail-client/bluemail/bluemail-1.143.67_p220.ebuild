# Copyright 2026 Stefano Balzarotti
# Distributed under the terms of the GNU General Public License v3

EAPI=8

inherit desktop xdg

# BlueMail ships for Linux only through the Snap Store, which serves each upload
# under a store revision rather than the app version. PV carries both as
# <app version>_p<snap revision>, so the download URL is fixed per release.
SNAP_ID="ZVlj0qw0GOFd5JgTfL8kk2Y5eIG1IpiH"
SNAP_REV="${PV##*_p}"

# QA-TEST: source image=gentoo/stage3:desktop@sha256:a5ef311f82bd949f3f1cab8f3b5d95aa84acc090c971bfc18b457e12ae7a4c79
# Thanks to Blix Inc., author of BlueMail (https://bluemail.me).
DESCRIPTION="Universal email and calendar client"
HOMEPAGE="https://bluemail.me"
SRC_URI="https://api.snapcraft.io/api/v1/snaps/download/${SNAP_ID}_${SNAP_REV}.snap -> ${P}.snap"

LICENSE="all-rights-reserved"
SLOT="0"
KEYWORDS="-* ~amd64"
RESTRICT="bindist mirror strip"

RDEPEND="
	app-accessibility/at-spi2-core:2
	app-crypt/libsecret
	dev-libs/expat
	dev-libs/glib:2
	dev-libs/nspr
	dev-libs/nss
	media-libs/alsa-lib
	media-libs/mesa[opengl]
	net-print/cups
	sys-apps/dbus
	virtual/libudev
	x11-libs/cairo
	x11-libs/gtk+:3
	x11-libs/libX11
	x11-libs/libXcomposite
	x11-libs/libXdamage
	x11-libs/libXext
	x11-libs/libXfixes
	x11-libs/libXrandr
	x11-libs/libnotify
	x11-libs/libxcb
	x11-libs/libxkbcommon
	x11-libs/pango
	x11-misc/xdg-utils
"
BDEPEND="sys-fs/squashfs-tools[lzma]"

QA_PREBUILT="opt/${PN}/*"

src_unpack() {
	# A .snap is a plain squashfs image: unsquashfs unpacks it without snapd.
	unsquashfs -quiet -no-progress -no-xattrs -dest "${S}" "${DISTDIR}/${P}.snap" || die
}

src_prepare() {
	default

	# The image root is world-writable; cp -a in src_install would keep that.
	chmod 755 . || die

	sed -i -e 's|^Icon=.*|Icon=bluemail|' meta/gui/bluemail.desktop || die

	# better-sqlite3 ships prebuilt addons for every platform; keep linux-x64.
	find resources/app.asar.unpacked/node_modules/better-sqlite3/prebuilds \
		-type f ! -name linux-x64.node -delete || die
}

src_install() {
	domenu meta/gui/bluemail.desktop
	newicon -s 1024 meta/gui/icon.png bluemail.png

	# Drop the snap scaffolding (metadata, confinement launch scripts, empty
	# content-plug mount points) and the Ubuntu libraries it bundles: the
	# system provides those through RDEPEND.
	rm -r meta lib usr data-dir gnome-platform scripts ./*.sh || die

	dodir "/opt/${PN}"
	cp -a . "${ED}/opt/${PN}/" || die
	dosym -r "/opt/${PN}/bluemail" /usr/bin/bluemail
}
