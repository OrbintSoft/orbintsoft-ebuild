# CLAUDE.md

Guidance for Claude (and any AI assistant) working in this repository.
Read this at the start of every session. The detailed roadmap lives in [PLAN.md](PLAN.md).

## What this repo is

`orbintsoft-ebuild` is a personal **Gentoo overlay** (EAPI 8, `masters = gentoo`,
thin manifests) maintained by Stefano Balzarotti / OrbintSoft. It ships ebuilds
for software not in the main Gentoo tree. Goal: raise quality to the point where
it can be published as a public, CI-tested overlay with automated version bumps.

## Working rules

1. **Minimal changes.** Keep changes small, especially breaking ones. If a change
   touches many files or many lines, split it into sub-steps tracked in a
   gitignored `<activity>-steps.md` so work can resume even if the repo doesn't
   compile or is incomplete. Intermediate sub-steps may leave the repo broken, but
   each completed PLAN.md item must be committable (Rule 9). **Ask for
   authorization before each step.**
2. **Propose new rules** when one would help — don't add them silently.
3. **After a long task, before starting a new one**, decide whether to stay in the
   same session. To save tokens: ask for a compact, or write down what's done /
   what's left and start a new chat. Exception: keep context when it matters for
   the next task(s).
4. **Feel free to add skills** to the project (`.claude/skills/`).
5. **Before opening a PR or declaring done, verify quality** — run linters and
   tests if they aren't too heavy.
6. **Repo language is English** (code, comments, docs, `elog`). Chat may be Italian.
7. **No sensitive data in committable files.** Never write personal data, anything
   about this machine/system, logs, or error output into a file that could be
   committed. That material goes only in gitignored scratch files.
8. **Step & scratch files.** A `<activity>-steps.md` holds the sub-steps of one
   PLAN.md activity. These — and any other scratch/working-memory files you create
   in the repo — are gitignored and free-form: store anything you need (logs,
   errors, notes), since they are never committed.
9. **Every PLAN.md item is committable when done.** Each plan item must leave the
   repo in a state that can be committed.
10. **Ask before committing.** Before each `git commit` (and before pushing), ask
   whether to commit — never commit or push unannounced. The user decides when.
11. **Check the current branch first.** At the start of a task and before every
   commit/push, run `git branch --show-current` and confirm you're on the intended
   feature branch (never `master`). The branch can change between turns — e.g. after
   a PR is merged — so never assume; verify.
12. **New file type → consider a linter.** Whenever a new kind or format of file
   first enters the repo (a new language, config/data format, etc.), evaluate
   whether a linter or validator exists for it and, if reasonable, add a
   `lint-<kind>` target wired into `make lint` (and CI). Record the decision —
   including a deliberate "no linter" — in PLAN.md.
13. **Don't embed one language inside another.** Never inline foreign-syntax
   content — a config-file body, another script, SQL, etc. — inside a heredoc or
   string literal of the host language. Author it as its own file of the proper
   type (so it can be read, diffed, and linted as that language) and have the host
   reference it: mount it, `source` it, or `sed`-substitute a committed template
   (`@TOKEN@` placeholders). Extends Rule 12. Writing a single literal value
   (`echo "x" > f`) is fine; a multi-line or structured fragment of another format
   is not. Examples: the in-container provisioning script (Phase 2.3) and the
   Portage `*.conf` templates under `scripts/test-portage/` (Phase 2.5), both
   extracted from bash heredocs.

### Proposed additional rules (pending approval)

- Once overall quality is high enough, require every touched ebuild to pass
  `pkgcheck scan` before "done". **Not enforced yet** — the repo does not pass
  pkgcheck today.
- Never hand-commit generated artifacts (`metadata/md5-cache`, `Manifest`) — let a
  `make` target or CI produce them. (Policy TBD — see PLAN.md Phase 0.8.)
- Every new package needs a `metadata.xml`, a correct copyright header, and tabs.

## Repository conventions

- **EAPI: the latest.** EAPI **9** was released 2025-12-14 and is supported by the
  installed Portage; it is the target for new and bumped ebuilds. Existing ebuilds
  are still EAPI 8 — migrate per PLAN.md (Phase 1.10). Adopt future EAPIs likewise.
- **Indentation: tabs** in `*.ebuild` / `*.eclass` (not spaces).
- **Copyright headers** (standardized in Phase 1.1; `pkgcheck scan` accepts them).
  Original work uses GPL-3:
  ```
  # Copyright <year> Stefano Balzarotti
  # Distributed under the terms of the GNU General Public License v3
  ```
  Files reworked from a Gentoo(-Authors) ebuild keep the upstream attribution and
  stay GPL-2:
  ```
  # Copyright 1999-<year> Gentoo Authors
  # Copyright <year> Stefano Balzarotti
  # Distributed under the terms of the GNU General Public License v2
  ```
- **Live ebuilds (`-9999`) are fine and currently the norm** — every package is
  live, and that's OK. Converting a package to a versioned ebuild (tracking
  upstream tags) is future, per-package work (Phase 3), only after CI + bump
  automation exist. Empty `KEYWORDS=""` on live ebuilds is good practice.
- Every package should have a `metadata.xml` (GLEP 68) with a real maintainer and,
  where applicable, an `<upstream><remote-id>` (needed by the future bump bot).
- **Upstream acknowledgement.** Every ebuild that packages third-party software
  carries a short `# Thanks to <author>, author of <project> (<url>).` comment above
  `DESCRIPTION`, crediting the *package* author (not the ebuild author). Skip it
  where the upstream author is OrbintSoft/Stefano, or for stub/dummy packages.
- **One package per step** when fixing ebuilds.
- **Commit messages: Conventional Commits — a *should*, not a *must*.** Prefer
  `type(scope): summary` (`feat`, `fix`, `chore`, `docs`, `refactor`, `ci`, …) for
  readability and future automation, but it is a recommendation, not enforced.

## How to verify (once tooling lands in Phase 1)

- `make lint`   → `pkgcheck scan` (+ `shellcheck` for scripts in `files/`)
- `make test`   → build/install changed packages in a Gentoo stage3 container
- `make manifest` / `make metadata` → regenerate Manifests / md5-cache

Until the Makefile exists, run `pkgcheck scan <category/package>` directly.
