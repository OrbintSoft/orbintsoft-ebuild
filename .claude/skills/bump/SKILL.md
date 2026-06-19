---
name: bump
description: >-
  Bump orbintsoft-ebuild packages to new upstream releases by driving the repo's
  version-bump engine (Tatsh/livecheck via `make livecheck`) and reviewing/opening
  the resulting PR. Use whenever updating an ebuild to a newer upstream version.
---

# bump — update ebuilds to new upstream releases

A thin wrapper around `make livecheck` (PLAN.md 3.5). It does **not** reimplement
version detection — livecheck reads each ebuild's `SRC_URI` and rewrites it (and
regenerates the Manifest) when a newer release exists. Authoritative rules live in
[CLAUDE.md](../../../CLAUDE.md) and [PLAN.md](../../../PLAN.md).

**Rule 1 still applies:** one package per step; **ask before committing** (Rule 10)
and confirm the branch is not `master` (Rule 11).

## Scope — what is bumpable

livecheck keys off the first `SRC_URI` URL, so only **versioned** ebuilds are in
scope. Live `-9999`/`-99999999` ebuilds have no `SRC_URI` version and are silently
skipped. As of writing the versioned packages are `media-fonts/nerd-fonts`,
`dev-util/fnm`, `sys-apps/fsearch`, `app-backup/redo-backups` (the set grows as
Phase 3.7 converts more live ebuilds). The weekly CI bot
(`.github/workflows/livecheck.yml`) does the same unattended and opens a bump PR.

## Prerequisites

- The overlay must be registered as a Portage repo: `make install` (needs root).
- A working Portage/livecheck environment (see CONTRIBUTING.md).

## Steps

1. **Branch.** `git branch --show-current`; if on `master`, create a bump branch
   (e.g. `git checkout -b livecheck/bump` or `bump/<pkg>`).
2. **Report.** `make livecheck` (whole overlay) or `make livecheck PKG=cat/name` —
   report-only, lists packages with a newer upstream version. No files change.
3. **Rewrite.** For the package(s) to bump:
   `make livecheck PKG=cat/name AUTO=1` — livecheck rewrites the ebuild to the new
   version and regenerates its Manifest. (`GIT=1` also commits and implies `AUTO`;
   prefer doing the commit yourself after review, per Rule 10.)
4. **Verify** (Rule 5): `make lint` (pkgcheck + xmllint) and
   `make test PKG=cat/name GETBINPKG=1` (build+install in a fresh stage3 container).
   A passing pkgcheck is **not** sufficient — the container test is the real gate
   (e.g. EAPI-9 `go-module` enforces a `>=dev-lang/go-<go.mod>` BDEPEND via an
   `install-qa-check.d` script that pkgcheck does not run).
5. **Review the diff**, especially: version-specific logic the rewrite may not have
   touched (USE flags, patches, dep changes between releases), and any per-package
   `-N` packaging suffix livecheck doesn't track.
6. **Commit + PR.** Ask before committing (Rule 10); use a `chore(bump)` /
   `fix`/`feat` message as appropriate; open the PR for review.
