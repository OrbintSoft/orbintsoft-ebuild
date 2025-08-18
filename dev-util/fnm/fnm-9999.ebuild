# /usr/local/portage/dev-util/fnm/fnm-9999.ebuild

EAPI=8

inherit cargo

RESTRICT="network-sandbox"
DESCRIPTION="Fast and simple Node.js version manager, built in Rust"
HOMEPAGE="https://github.com/Schniz/fnm"
LICENSE="MIT"
SLOT="0"
KEYWORDS="amd64"

EGIT_REPO_URI="https://github.com/Schniz/fnm.git"
EGIT_BRANCH="master"
SRC_URI=""

DEPEND="dev-lang/rust"
RDEPEND="${DEPEND}"

src_unpack() {
    cd "${WORKDIR}" || die
    # shallow clone to save time
    git clone https://github.com/Schniz/fnm.git "${S}" || die
    cd "${S}" || die
    latest_tag="$(git describe --tags "$(git rev-list --tags --max-count=1)")" || die
    einfo "Checking out latest tag: ${latest_tag}"
    git fetch --tags || die
    git checkout "${latest_tag}" || die
}

src_compile() {
    cargo build --release || die "cargo build failed"
}

src_install() {
    dodir /opt/fnm
    install -Dm755 target/release/fnm "${ED}/opt/fnm/fnm" || die
}

pkg_postinst() {
    elog "fnm installed to /opt/fnm/fnm"
    elog "Built from tag: $(git -C "${S}" describe --tags --abbrev=0)"
}
