# Copyright 2026 Stefano Balzarotti
# Distributed under the terms of the GNU General Public License v3

EAPI=8

# Thanks to koalaman, author of ShellCheck (https://github.com/koalaman/shellcheck).
DESCRIPTION="Shell script analysis tool (built from source)"
HOMEPAGE="https://www.shellcheck.net/"
LICENSE="GPL-3"
SLOT="0"
KEYWORDS=""

# cabal needs network access to fetch the Haskell dependencies
RESTRICT="network-sandbox test"

EGIT_REPO_URI="https://github.com/koalaman/shellcheck.git"

DEPEND="
	>=dev-lang/ghc-8.10.6
	dev-haskell/cabal-install
"

S="${WORKDIR}/shellcheck"

src_unpack() {
	cd "${WORKDIR}" || die
	# shallow clone to save time
	git clone --depth 1 "${EGIT_REPO_URI}" "${S}" || die
	cd "${S}" || die
	git fetch --tags --depth 1 || die
	latest_tag="$(git tag --sort=-version:refname | head -n1)" || die
	einfo "Checking out latest tag: ${latest_tag}"
	git checkout "${latest_tag}" || die
}

src_compile() {
	# keep cabal's state inside the build dir
	export HOME="${T}"
	cabal update || die "cabal update failed"
	cabal build exe:shellcheck || die "cabal build failed"
}

src_install() {
	local bin
	bin="$(cabal list-bin exe:shellcheck)" || die "could not locate built binary"
	dobin "${bin}"

	dodoc README.md

	# the man page is generated from shellcheck.1.md via pandoc;
	# build and install it only if pandoc is available
	if type -P pandoc >/dev/null && [[ -f shellcheck.1.md ]]; then
		pandoc -s -t man shellcheck.1.md -o shellcheck.1 \
			|| die "man page generation failed"
		doman shellcheck.1
	else
		einfo "pandoc not found or shellcheck.1.md missing; skipping man page"
	fi
}

pkg_postinst() {
	elog "shellcheck built from tag: $(git -C "${S}" describe --tags --abbrev=0 2>/dev/null)"
}
