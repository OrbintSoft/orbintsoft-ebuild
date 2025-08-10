EAPI=8
DESCRIPTION="Dummy package to satisfy dependencies without installing anything"
HOMEPAGE="https://gentoo.org"
LICENSE="metapackage"
KEYWORDS="amd64 x86"
S="${WORKDIR}"
SLOT="6"

src_install() {
    einfo "Nothing to install."
}
