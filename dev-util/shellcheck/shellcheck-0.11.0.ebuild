# Copyright 1999-2026 Gentoo Authors
# Copyright 2026 Stefano Balzarotti
# Distributed under the terms of the GNU General Public License v2

EAPI=8

CABAL_PN="ShellCheck"

CABAL_FEATURES="lib profile haddock hoogle hscolour test-suite"
inherit haskell-cabal

# QA-TEST: source
# Thanks to koalaman, author of ShellCheck (https://github.com/koalaman/shellcheck).
DESCRIPTION="Shell script analysis tool (built from source)"
HOMEPAGE="https://www.shellcheck.net/"

LICENSE="GPL-3"
SLOT="0/${PV}"
KEYWORDS="~amd64"

# One upstream test (prop_checkOverwrittenExitCode8) trips an undefined array
# element and fails, so the suite is built but not run.
RESTRICT="test"

RDEPEND="
	>=dev-haskell/aeson-1.4.0:=[profile?] <dev-haskell/aeson-2.3:=[profile?]
	>=dev-haskell/diff-0.4.0:=[profile?] <dev-haskell/diff-1.1:=[profile?]
	>=dev-haskell/parsec-3.1.14:=[profile?] <dev-haskell/parsec-3.2:=[profile?]
	>=dev-haskell/quickcheck-2.14.2:=[profile?] <dev-haskell/quickcheck-2.17:=[profile?]
	>=dev-haskell/regex-tdfa-1.2.0:=[profile?] <dev-haskell/regex-tdfa-1.4:=[profile?]
	>=dev-lang/ghc-8.10.6:=
	|| (
		( >=dev-haskell/fgl-5.7.0 <dev-haskell/fgl-5.8.1.0 )
		( >=dev-haskell/fgl-5.8.1.1 <dev-haskell/fgl-5.9 )
	)
	dev-haskell/fgl:=[profile?]
"
DEPEND="${RDEPEND}
	>=dev-haskell/cabal-3.2.1.0
"
