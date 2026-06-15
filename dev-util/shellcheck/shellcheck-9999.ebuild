# Copyright 2026 Stefano Balzarotti
# Distributed under the terms of the GNU General Public License v3

EAPI=9

inherit git-r3

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

src_unpack() {
	# git-r3 guarantees dev-vcs/git and performs the clone; then pin to the
	# latest release tag (mirrors sys-apps/fsearch).
	git-r3_src_unpack
	cd "${S}" || die
	einfo "Fetching tags..."
	git fetch --tags || die
	latest_tag="$(git describe --tags "$(git rev-list --tags --max-count=1)")" || die
	einfo "Checking out latest tag: ${latest_tag}"
	git checkout "${latest_tag}" || die
	# persist the tag for pkg_postinst: the build tree is not reliably
	# available there, but ${T} survives across all phases of this build.
	echo "${latest_tag}" > "${T}/built-tag" || die
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
	elog "shellcheck built from tag: $(cat "${T}/built-tag" 2>/dev/null)"
}
