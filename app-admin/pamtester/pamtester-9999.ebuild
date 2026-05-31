# Copyright 2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit git-r3

DESCRIPTION="Non-interactive PAM testing tool"
HOMEPAGE="https://github.com/thkukuk/pamtester"
EGIT_REPO_URI="https://github.com/thkukuk/pamtester.git"

LICENSE="BSD"
SLOT="0"
KEYWORDS="amd64"
IUSE=""

DEPEND="
	sys-libs/pam
"
RDEPEND="${DEPEND}"

src_prepare() {
	default
}
