# Improvement Plan — orbintsoft-ebuild

Roadmap to raise the quality of this Gentoo overlay to a published, CI-tested,
auto-updated state. Operational rules for assistants live in [CLAUDE.md](CLAUDE.md).

**Status legend:** `[ ]` todo · `[~]` in progress · `[x]` done

**Invariant:** every item below must leave the repo in a committable state when
done. Large items are broken into sub-steps tracked in a gitignored
`<activity>-steps.md` (free-form scratch — see CLAUDE.md rules 7–9).

---

## Decisions taken (durable policy)

- Plan lives in `CLAUDE.md` (rules) + `PLAN.md` (roadmap).
- License **GPL-3** for the repo; copyright headers in three tiers — original →
  `Stefano Balzarotti`/GPL-3; reworked from a Gentoo(-Authors) ebuild → dual
  `Gentoo Authors` + `Stefano Balzarotti`/GPL-2 (pamtester, tvision, bt-keys-sync,
  fsearch, claude-desktop, nerd-fonts). `pkgcheck` accepts both.
- Linters: **pkgcheck** + **pkgdev** + **shellcheck**. CI tests **only packages
  changed in the PR**, in a `gentoo/stage3` container; never the whole suite.
- **No INI linter** — deliberate no-linter decision (Rule 12) for `checkmake.ini`,
  the repo's only INI file; revisit if a suitable linter turns up.
- **Haskell test realism:** packages whose deps live in gentoo-haskell carry
  `overlay=haskell` on their `# QA-TEST:` line; the test container then registers the
  gentoo-haskell overlay (priority 50 — wins ties over ::gentoo, bind-mounted from the
  host or fetched as a tarball in CI) so their deps build from it, as a Gentoo Haskell
  system does. Rule 15: tracked rolling (`HASKELL_REF=master`, auto-current by
  construction — realism over reproducibility); pin via `HASKELL_REF` if ever needed.
- Publishing: a **git overlay on GitHub**, no server.
- **EAPI 9** (since 2025-12-14) is the target for new/bumped ebuilds; older ebuilds
  migrate in Phase 6 (eclass-gated). Future EAPIs adopted likewise.
- **Live `-9999` ebuilds are fine** and stay until a per-package live→versioned
  conversion is justified (only after CI + bump automation — done in Phase 3).
- **md5-cache** is gitignored and tool-generated (`egencache`/CI), never hand-committed.
- **Bump automation, two layers:** Dependabot + Renovate for non-ebuild pins (split
  scope, decided 3.3 — Dependabot owns the GitHub Actions, Renovate the Go lint tools
  and the `gentoo/stage3` digest), and an ebuild bump bot —
  [Tatsh/livecheck](https://github.com/Tatsh/livecheck) (decided 3.5), keying off
  `SRC_URI` (versioned ebuilds only).
- **Commit messages:** Conventional Commits as a *should*, not a *must*.

## Open questions
- _(none)_

---

## Phases 0–4 — done

Foundations, QA tooling (`make lint`/`test`/`manifest`/`metadata`), CI (`lint.yml` +
`test.yml`), the `/new-ebuild` and `/bump` skills plus the rest of the bump automation,
and the first new packages (`redo-backups`, `turbo`, `shellcheck`) are all done. Detail
is in git history, not here; durable decisions from this work are in "Decisions taken"
above and in CLAUDE.md.

## Phase 5 — Publishing  `[x]`

Make the overlay easy to discover and adopt, and let people support the work.

- [x] **5.1** README overhaul — clearer structure and copy: what the overlay is, how to
      enable it (both `eselect repository` and the manual `repos.conf`, already drafted),
      per-package notes (added a live/release/stub column), and an honest quality/contribution
      status. Absorbs 5.2.
- [x] **5.2** EAPI accuracy in the README — the header now states the real mix (EAPI 9 for
      new/migrated ebuilds, EAPI 8 where an inherited eclass caps it until Phase 6). Also
      corrected the stale "most ebuilds are live" claim (it is now a ~half-and-half mix).
- [x] **5.3** `.github/FUNDING.yml` — three sponsor links: `github: OrbintSoft`
      (https://github.com/sponsors/OrbintSoft), a custom `https://paypal.me/orbintsoft`, and a
      custom `https://www.gentoo.org/donate/` so the upstream distro is credited too. Covered
      by `lint-yaml` (GitHub-schema YAML, no new linter); static links, nothing to bump.
- [x] **5.4** List the overlay officially so it's reachable from `eselect repository` (the
      curated list), `layman`, and https://gpo.zugaina.org/ — all three read the **same**
      official Gentoo overlay list (`repositories.xml`), so one action covers them: a PR to
      [gentoo/api-gentoo-org](https://github.com/gentoo/api-gentoo-org) adding a `<repo>`
      entry (name `orbintsoft`, status unofficial / quality experimental, owner, git source,
      atom feed). **Verify compliance first:** `profiles/repo_name` == `orbintsoft`,
      `metadata/layout.conf` `masters = gentoo`, public git URL, and a reasonable `pkgcheck`
      state. This registers a *personal, unofficial* overlay (not a contribution to the
      Gentoo tree); the entry is only metadata pointing at the repo, so AI-authorship is
      irrelevant to the listing. _Listing PR merged upstream; confirmed live in the official
      `repositories.xml` (status unofficial, quality experimental, correct owner/sources/feed)
      and discoverable via `eselect repository list`._

## Phase 6 — EAPI 9 migration (eclass-gated)  `[ ]`

The 6 packages still on EAPI 8 inherit eclasses that cap at EAPI 8 in the Gentoo tree.
Each can only move to EAPI 9 once its eclass gains EAPI 9 support upstream. The path is
to **submit PRs to Gentoo** adding EAPI 9 to those eclasses (or wait for in-flight
upstream work). Gentoo does not accept AI-authored commits, so **Stefano authors these
PRs by hand and Claude only reviews**; this overlay forks no eclass and reverts nothing
to manual builds. A package flips `EAPI=8`→`9` only after its eclass — and its whole
inherit chain — is EAPI-9-capable in the synced tree, gated by `make test`.

### The gate: supported-EAPI guard + inherit chain

An eclass accepts EAPI 9 only when its supported-EAPI guard lists `9` **and** every
eclass it inherits already does. EAPI 9 is largely *additive* — its headline features
(`pipestatus`, `ver_replacing`) are new commands, backported for older EAPIs via
`eapi9-pipestatus` / `eapi9-ver`, not removals — and the util eclasses already migrated
in the tree needed no 9-specific code, only the guard bump. So per eclass the real work
is small: add `9)` to the guard, audit the phase functions, test.

**Already EAPI-9-ready** in these chains (no work): `git-r3`, `flag-o-matic`,
`toolchain-funcs`, `multiprocessing`, `multilib-build`, `sysroot`, `out-of-source-utils`,
`multibuild`.

**Leaf eclasses still capped at 8** — they inherit only ready eclasses, so each is
PR-able upstream now with no prerequisite:

| eclass | inherits | unblocks |
|---|---|---|
| `ninja-utils` | multiprocessing ✓ | `meson` + `cmake` |
| `xdg-utils` | (none) | `cmake` + `xdg` |
| `font` | (none) | nerd-fonts |
| `vala` | flag-o-matic ✓ | polo |
| `rust`, `rust-toolchain` | (none) | `cargo` |
| `python-utils-r1` | multiprocessing ✓, toolchain-funcs ✓ | `meson` |

**Blocked until a leaf lands first:** `meson` (← `ninja-utils` + `python-utils-r1`),
`cmake` (← `ninja-utils` + `xdg-utils`), `xdg` (← `xdg-utils`),
`cargo` (← `rust` + `rust-toolchain`).

### Per-package gate (easiest first)

Before authoring any eclass PR, check gentoo.git / the bug tracker for in-flight EAPI 9
work — core eclasses (`cmake`, `meson`, `python-utils-r1`, `xdg-utils`) may gain it via
sync on their own. When flipping a package: bump `EAPI`, audit the ebuild body for any
EAPI-9 behavioral change, and confirm with `make test PKG=<cat/pkg>`.

- [ ] **6.1** `media-fonts/nerd-fonts` — gate: `font` (single standalone leaf). Smallest
      and self-contained; do first to prove the workflow end to end.
- [ ] **6.2** `dev-libs/tvision` — gate: `cmake` (= `ninja-utils` + `xdg-utils`, two small
      leaves); also inherits `git-r3` ✓.
- [ ] **6.3** `x11-misc/polo` — gate: `xdg` (← `xdg-utils`) + `vala`; also `git-r3` ✓.
- [ ] **6.4** `app-admin/pamtester`, `sys-apps/fsearch` — gate: `meson`
      (= `ninja-utils` + `python-utils-r1`). Longest path: `python-utils-r1` is a
      heavyweight, high-scrutiny eclass.
- [ ] **6.5** `dev-util/fnm` — gate: `cargo` (= `rust` + `rust-toolchain`).
