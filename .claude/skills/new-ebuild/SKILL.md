---
name: new-ebuild
description: >-
  Scaffold a new package (ebuild + metadata.xml) for the orbintsoft-ebuild Gentoo
  overlay, following all repo conventions: EAPI (9, eclass-gated), copyright tiers,
  upstream-credit comment, canonical variable order, GLEP 68 metadata, tabs/LF.
  Use whenever adding a new ebuild/package to this overlay.
---

# new-ebuild — scaffold a new overlay package

Create a new `category/package/` with an ebuild and a `metadata.xml` that match this
overlay's conventions on the first try, so `make lint` and `make test` pass with
minimal follow-up. Authoritative rules live in [CLAUDE.md](../../../CLAUDE.md) and
[PLAN.md](../../../PLAN.md); this skill operationalizes them.

**Rule 1 still applies:** one package per step, and ask before committing (Rule 10).

## 1. Interview — gather these before writing anything

1. **`category/package`** — category must already exist in
   [profiles/categories](../../../profiles/categories). If it does not, adding it is a
   separate `profiles/` change; flag it.
2. **Upstream URL** (GitHub/GitLab/…) and **author** — needed for HOMEPAGE,
   `remote-id`, and the credit comment.
3. **Live or versioned?** Live `-9999` tracks the default branch (the overlay norm);
   versioned tracks a release tag. When in doubt, **live** (CLAUDE.md: live is fine).
4. **Build system → eclasses.** e.g. plain Makefile (no build eclass), `cmake`,
   `meson`, `cargo`+`rust`, autotools, `haskell-cabal`, `font`, `xdg`. Live ebuilds
   also `inherit git-r3`.
5. **Authorship tier** — is the software OrbintSoft/Stefano's own work, third-party,
   or a stub/dummy? (Drives copyright header + credit comment.)
6. **License** — must be a token that exists in the Gentoo `licenses/` tree
   (`pkgcheck` flags unknown tokens, see PLAN.md 1.9). Use the upstream's real license.
7. **USE flags** (`IUSE`) and **dependencies** (`DEPEND`/`RDEPEND`/`BDEPEND`).

## 2. Decision rules (the non-obvious parts)

### EAPI — default 9, but eclass-gated
Target **`EAPI=9`**. An ebuild can only be EAPI 9 if *none* of its inherited eclasses
caps at EAPI 8. As of the 2026-06-12 tree snapshot the still-EAPI-8 eclasses are
**`cargo`, `rust`, `cmake`, `meson`, `font`, `xdg`**; `git-r3` is EAPI-9-ready. If you
inherit any capped eclass, use **`EAPI=8`** (see PLAN.md 1.10 / Phase 6). Don't trust
the snapshot blindly — verify against the installed tree when unsure:
`grep -nE 'EAPI[ )]' /var/db/repos/gentoo/eclass/<name>.eclass` (look at its
`case ${EAPI} in` block). Never fork an eclass or hand-roll a build to dodge the cap.

### Copyright header — two tiers (CLAUDE.md)
- **Original work** (OrbintSoft/Stefano, or a stub): GPL-3.
  ```
  # Copyright <year> Stefano Balzarotti
  # Distributed under the terms of the GNU General Public License v3
  ```
- **Reworked from a Gentoo(-Authors) ebuild**: keep upstream attribution, GPL-2.
  ```
  # Copyright 1999-<year> Gentoo Authors
  # Copyright <year> Stefano Balzarotti
  # Distributed under the terms of the GNU General Public License v2
  ```
  `<year>` is the current year; use a range (`2025-2026`) only if there's real prior
  history for this file.

### Upstream-credit comment (CLAUDE.md)
For third-party software, one line **directly above `DESCRIPTION`**, crediting the
*package* author (not the ebuild author):
```
# Thanks to <author>, author of <project> (<url>).
```
**Skip it** when the upstream author is OrbintSoft/Stefano, or for stub/dummy packages.

### Test strategy — `# QA-TEST:` (CLAUDE.md Rule 17)
Every ebuild declares how the container test builds it:
```
# QA-TEST: source        # default; always works (the safe fallback)
# QA-TEST: binpkg         # deps from the gentoo binhost (--binpkg-respect-use=n)
# QA-TEST: binpkg-respect-use   # binhost with --binpkg-respect-use=y
# QA-TEST: binpkg image=<stage3-tag>   # optional per-package container image
```
Default to **`source`**. Use **`binpkg`** only when the package would otherwise be
slow to build (heavy toolchain/GUI chain: GHC, Rust, gtk+/mesa/LLVM) **and** its
binhost closure is consistent — verify with a passing `make test PKG=…`. The binhost
can't serve the whole suite (systemd into the openrc stage3 + `abi_x86_32` multilib +
version skew, PLAN.md 2.6–2.7), so live/`git-r3` packages that drag in the gtk+/systemd
chain stay `source`. The harness falls back to source on a binpkg failure, but pick the
directive that actually works to avoid a wasted attempt.

## 3. Ebuild layout

Order, with tabs for indentation and LF line endings:

1. Copyright header (tier from §2) + license line
2. blank line
3. `EAPI=<n>`
4. blank line
5. `inherit <eclasses>` (build-system eclass; add `git-r3` for live)
6. blank line
7. the `# QA-TEST: <strategy>` directive (§2), then *(third-party only)* the
   `# Thanks to …` credit comment
8. `DESCRIPTION`, `HOMEPAGE`, then `EGIT_REPO_URI="…git"` (**live**) or
   `SRC_URI=…` + `S=…` (**versioned**)
9. blank line
10. `LICENSE`, `SLOT`, `KEYWORDS`, `IUSE` — **canonical order**
    `DESCRIPTION/HOMEPAGE/S/LICENSE/SLOT/KEYWORDS/IUSE` (PLAN.md 1.15). Live ⇒
    `KEYWORDS=""` (good practice). Versioned ⇒ the tested arch (e.g. `~amd64`) or empty
    per overlay policy.
11. `DEPEND` / `RDEPEND` / `BDEPEND`
12. Phase functions — prefer the eclass defaults; only override `src_configure`/
    `src_compile`/`src_install` when the eclass default isn't enough.

Don't emit redundant empty global assignments (`IUSE=""`, `SRC_URI=""`, etc.) —
`pkgcheck`'s `EmptyGlobalAssignment` flags them (PLAN.md 1.7).

### Reference ebuilds in this repo (copy the closest, don't reinvent)
| Use case | Look at |
|---|---|
| original-work, live, plain Makefile | [app-crypt/sshepherd](../../../app-crypt/sshepherd/sshepherd-9999.ebuild) |
| third-party, live, `cmake` (EAPI 8) | [dev-libs/tvision](../../../dev-libs/tvision/tvision-9999.ebuild) |
| third-party, live, `cargo`+`rust` | [dev-util/fnm](../../../dev-util/fnm/fnm-9999.ebuild) |
| versioned + `Manifest` + USE-flag docs | [media-fonts/nerd-fonts](../../../media-fonts/nerd-fonts/nerd-fonts-3.2.1.ebuild) |
| build-time network fetch (`RESTRICT`) | [app-misc/claude-desktop](../../../app-misc/claude-desktop/claude-desktop-9999.ebuild) |

## 4. metadata.xml (GLEP 68, tabs)

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE pkgmetadata SYSTEM "https://www.gentoo.org/dtd/metadata.dtd">
<pkgmetadata>
	<maintainer type="person">
		<email>stefano.balzarotti@orbintsoft.net</email>
		<name>Stefano Balzarotti</name>
	</maintainer>
	<upstream>
		<remote-id type="github">OWNER/REPO</remote-id>
	</upstream>
</pkgmetadata>
```
- Pick the right `remote-id type` (`github`, `gitlab`, …); Repology and the future
  tag census (PLAN.md 3.7) rely on it.
- Document every **local** USE flag with `<use><flag name="…">…</flag></use>` or
  `pkgcheck` raises `UnknownUseFlags` (PLAN.md 1.3).

## 5. After scaffolding — verify (Rule 5)

1. **`make lint`** — pkgcheck + xmllint (+ shellcheck/checkmake/yamllint). Fix findings
   before declaring done; this is the gate `pkgcheck scan category/package` enforces.
2. **`make test PKG=category/package`** — build+install in a fresh stage3 container.
3. **Versioned only:** generate the Manifest (`make manifest` / `pkgdev manifest`).
   Live ebuilds have no DIST artifacts → no Manifest (PLAN.md 1.16). A versioned
   ebuild whose first `SRC_URI` points at a recognized host (GitHub releases, PyPI,
   …) is auto-bumpable by `make livecheck` (PLAN.md 3.5) with no `livecheck.json` —
   prefer such a `SRC_URI` so future bumps stay automatic.
4. Add the package to the README list if there is one (PLAN.md 0.5).
5. If you created a new **category**, update [profiles/categories](../../../profiles/categories).
6. Stop and **ask before committing** (Rule 10); confirm the branch is not `master`
   (Rule 11).
