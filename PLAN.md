# Improvement Plan — orbintsoft-ebuild

Roadmap to raise the quality of this Gentoo overlay to a published, CI-tested,
auto-updated state. Operational rules for assistants live in [CLAUDE.md](CLAUDE.md).

**Status legend:** `[ ]` todo · `[~]` in progress · `[x]` done

**Invariant:** every item below must leave the repo in a committable state when
done. Large items are broken into sub-steps tracked in a gitignored
`<activity>-steps.md` (free-form scratch — see CLAUDE.md rules 7–9).

---

## Decisions taken

- Plan stored in `CLAUDE.md` (rules) + `PLAN.md` (roadmap).
- Start from **Phase 0**.
- Repository to be renamed `local` → `orbintsoft`.
- License: **GPL-3** for the whole repo.
- Linters: **pkgcheck** + **pkgdev** (canonical Gentoo QA) + **shellcheck** for scripts.
- CI: GitHub Actions, **test only packages changed in the PR**, in a `gentoo/stage3` container.
- Publishing: as a **git overlay on GitHub, no server needed**.
- Version-bump automation: **custom bot** (nvchecker-based) — Dependabot/Renovate
  cannot bump ebuilds, only GitHub Actions pins.
- **Live `-9999` ebuilds stay as-is for now** (all packages are live, that's fine).
  Live→versioned conversion is future, per-package, decided dep by dep — only after
  CI + bump automation exist.

## Open questions

- md5-cache policy: gitignore vs. regenerate-and-commit in CI? (Phase 0)
- Commit-message convention to adopt? (Conventional Commits?)
- Heavy builds (shellcheck→GHC, fnm→Rust) in CI: allowlist / on-demand / timeout?
- Confirm pkgcheck accepts a GPL-3 copyright header (it may warn).

---

## Phase 0 — Foundations  `[~]`

Low risk, no build logic. Unblocks publishing as a real overlay.

- [ ] **0.1** `profiles/repo_name`: `local` → `orbintsoft` ⚠️ breaking for existing users
- [ ] **0.2** `profiles/categories`: complete list (all 10 categories in use)
- [ ] **0.3** `LICENSE`: MIT → GPL-3
- [ ] **0.4** `metadata/layout.conf`: add `manifest-hashes`, `cache-formats`, repo metadata
- [ ] **0.5** `README.md`: what the overlay is, how to enable it (`repos.conf` / `eselect repository`), package list, contributing pointer
- [ ] **0.6** `CONTRIBUTING.md`
- [ ] **0.7** `.editorconfig` (tabs for `*.ebuild`/`*.eclass`) + `.gitignore`
      (must ignore `*-steps.md` and scratch/working-memory files — Rules 7–9)
- [ ] **0.8** Decide & apply md5-cache policy
- [x] **0.9** `CLAUDE.md` + `PLAN.md` (this commit)

## Phase 1 — QA tooling & ebuild fixes  `[ ]`

`make lint`/`test`/`manifest`/`metadata` + pkgcheck/shellcheck, then fix issues
**one package per step** (Rule 1).

- [ ] **1.0** `Makefile` with lint/test/manifest/metadata/install targets
- [ ] **1.1** Standardize copyright headers (GPL-3) across all ebuilds
- [ ] **1.2** Normalize indentation to tabs
- [ ] **1.3** Add missing `metadata.xml` for all packages; fix `claude-desktop` placeholder
- [ ] **1.4** Fix `app-admin/pamtester` (broken: no compile/install)
- [ ] **1.5** Fix `x11-misc/polo` (`src_configure` runs emake; autotools never reconf'd)
- [ ] **1.6** Fix `dev-util/fnm` (use cargo eclass properly; install to /usr/bin not /opt)
- [ ] **1.7** Empty `KEYWORDS` on live ebuilds; remove stray path comments
- [ ] **1.8** Remove Italian text from `app-misc/claude-desktop` `pkg_postinst`
- [ ] **1.9** Verify `dev-libs/tvision` `LICENSE="MIT freed"` against the licenses tree

## Phase 2 — CI  `[ ]`

- [ ] **2.1** Workflow: compute changed packages from the PR diff → dynamic matrix
- [ ] **2.2** Run `pkgcheck scan` on changed packages
- [ ] **2.3** `emerge` changed packages in `gentoo/stage3` (binpkg cache; heavy-build policy)

## Phase 3 — Automation  `[ ]`

- [ ] **3.1** Renovate/Dependabot for GitHub Actions pins only
- [ ] **3.2** (Future, optional, per-package) Convert live `-9999` → versioned
      ebuilds where it makes sense and upstream has releases. Decided dep by dep,
      only after CI + bump automation. Not a goal in itself — live is fine.
- [ ] **3.3** nvchecker-based bot: on new upstream release, open a PR adding the new
      versioned ebuild + regenerated Manifest
- [ ] **3.4** (Optional) `/new-ebuild` and `/bump` Claude skills reused by the bot

## Phase 4 — Publishing  `[ ]`

- [ ] **4.1** README instructions to add the overlay via `repos.conf`
- [ ] **4.2** (Optional) PR to the official `repo/proj/overlays` list for `eselect repository`

---

## Known issues inventory (resume-friendly)

| # | Package / file | Issue | Phase |
|---|---|---|---|
| 1 | `profiles/categories` | only `net-wireless` listed | 0.2 |
| 2 | `profiles/repo_name` | `local` (collides, blocks publishing) | 0.1 |
| 3 | `LICENSE` | MIT, want GPL-3 | 0.3 |
| 4 | `metadata/md5-cache` | committed but incomplete (5/11), generated artifact | 0.8 |
| 5 | all ebuilds | inconsistent copyright headers (some wrongly "Gentoo Authors") | 1.1 |
| 6 | 6 vs 5 ebuilds | mixed tabs/spaces | 1.2 |
| 7 | 8/11 packages | missing `metadata.xml`; `claude-desktop` has placeholder maintainer | 1.3 |
| 8 | `app-admin/pamtester` | broken: only `src_prepare`, no compile/install | 1.4 |
| 9 | `x11-misc/polo` | `src_configure(){ emake }`; autotools never reconf'd | 1.5 |
| 10 | `dev-util/fnm` | ignores cargo eclass; manual git clone; installs to `/opt` | 1.6 |
| 11 | live ebuilds | non-empty `KEYWORDS`; stray path comments at top | 1.7 |
| 12 | `app-misc/claude-desktop` | Italian text in `pkg_postinst` | 1.8 |
| 13 | `dev-libs/tvision` | `LICENSE="MIT freed"` to verify | 1.9 |
| 14 | repo | no README/CONTRIBUTING/.editorconfig/.gitignore/Makefile/CI | 0/1/2 |
