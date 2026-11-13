# Copyright 2026 Stefano Balzarotti
# Distributed under the terms of the GNU General Public License v3

EAPI=9

inherit autotools

# QA-TEST: source
# Thanks to Thomas Tsai, author of Partclone (https://github.com/Thomas-Tsai/partclone).
DESCRIPTION="Utilities to save and restore only used blocks on a partition"
HOMEPAGE="https://partclone.org https://github.com/Thomas-Tsai/partclone"
SRC_URI="https://github.com/Thomas-Tsai/partclone/archive/refs/tags/${PV}.tar.gz -> ${P}.tar.gz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64"
# reiser4, ufs and vmfs are omitted: their libraries (libaal/reiser4progs,
# libufs, vmfs-tools) are not packaged in the Gentoo tree.
IUSE="apfs btrfs +e2fs exfat f2fs fat fuse hfs isal jfs minix ncurses nilfs2 ntfs reiserfs static xfs xxhash"

# libblkid (btrfs) and libuuid come from sys-apps/util-linux, always pulled in.
RDEPEND="
	app-arch/zstd:=
	dev-libs/openssl:=
	sys-apps/util-linux
	virtual/zlib
	e2fs? ( sys-fs/e2fsprogs )
	fuse? ( sys-fs/fuse:3 )
	isal? ( dev-libs/isa-l )
	jfs? ( sys-fs/jfsutils )
	ncurses? ( sys-libs/ncurses:= )
	nilfs2? ( sys-fs/nilfs-utils )
	ntfs? ( sys-fs/ntfs3g )
	reiserfs? ( sys-fs/progsreiserfs )
	xfs? ( dev-libs/userspace-rcu:= )
	xxhash? ( dev-libs/xxhash )
"
DEPEND="${RDEPEND}"
BDEPEND="virtual/pkgconfig"

src_prepare() {
	default
	eautoreconf
}

src_configure() {
	local myeconfargs=(
		$(use_enable apfs)
		$(use_enable btrfs)
		$(use_enable e2fs extfs)
		$(use_enable exfat)
		$(use_enable f2fs)
		$(use_enable fat)
		$(use_enable fuse)
		$(use_enable hfs hfsp)
		$(use_enable isal)
		$(use_enable jfs)
		$(use_enable minix)
		$(use_enable ncurses ncursesw)
		$(use_enable nilfs2)
		$(use_enable ntfs)
		$(use_enable reiserfs)
		$(use_enable static static-linking)
		$(use_enable xfs)
		$(use_enable xxhash)
	)
	econf "${myeconfargs[@]}"
}
