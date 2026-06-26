# orbintsoft-ebuild

[![Lint](https://github.com/OrbintSoft/orbintsoft-ebuild/actions/workflows/lint.yml/badge.svg)](https://github.com/OrbintSoft/orbintsoft-ebuild/actions/workflows/lint.yml)
[![Test](https://github.com/OrbintSoft/orbintsoft-ebuild/actions/workflows/test.yml/badge.svg)](https://github.com/OrbintSoft/orbintsoft-ebuild/actions/workflows/test.yml)
[![License: GPL-3.0](https://img.shields.io/badge/License-GPL--3.0-blue.svg)](LICENSE)
[![Sponsor](https://img.shields.io/badge/Sponsor-%E2%9D%A4-ea4aaa?logo=githubsponsors&logoColor=white)](https://github.com/sponsors/OrbintSoft)

A personal [Gentoo](https://www.gentoo.org/) overlay maintained by Stefano
Balzarotti / OrbintSoft. It ships ebuilds for software that is not in the main
Gentoo tree, or for variants of it.

- **EAPI:** 8 and 9 — EAPI 9 for new and migrated ebuilds, EAPI 8 where an
  inherited eclass does not yet support 9
- **masters:** `gentoo` · **manifests:** thin · **repository name:** `orbintsoft`
- **License:** [GPL-3.0](LICENSE) for the overlay's own files (each packaged
  program keeps its own upstream license, declared per ebuild)

> ⚠️ This is a personal, work-in-progress overlay. Its ebuilds are a mix of
> **versioned releases** and **live** (`-9999`) ebuilds that track upstream
> `master`/`main`. See [PLAN.md](PLAN.md) for the quality roadmap.

## Enabling the overlay

### Option A — `eselect repository` (recommended)

```sh
# install app-eselect/eselect-repository if you don't have it
eselect repository add orbintsoft git https://github.com/OrbintSoft/orbintsoft-ebuild.git
emaint sync -r orbintsoft
```

### Option B — manual `repos.conf`

Create `/etc/portage/repos.conf/orbintsoft.conf`:

```ini
[orbintsoft]
location = /var/db/repos/orbintsoft
sync-type = git
sync-uri = https://github.com/OrbintSoft/orbintsoft-ebuild.git
auto-sync = yes
```

Then:

```sh
emaint sync -r orbintsoft
```

Once enabled, install packages as usual, e.g. `emerge -av sys-apps/fsearch`.
Live (`-9999`) ebuilds carry empty `KEYWORDS`, so you may need to accept them
first, e.g.:

```sh
echo '=sys-apps/foo-9999 **' >> /etc/portage/package.accept_keywords
```

### Haskell-based packages need the gentoo-haskell overlay

Some packages here are built from Haskell sources (currently
`dev-util/shellcheck`). Their dependency chain is maintained in the
[gentoo-haskell](https://github.com/gentoo-haskell/gentoo-haskell) overlay, so
enable it before installing them:

```sh
eselect repository enable haskell
emaint sync -r haskell
```

## Packages

| Package | Type | Description |
|---|---|---|
| `app-admin/pamtester` | live | Non-interactive PAM testing tool |
| `app-backup/redo-backups` | release | Create backups compatible with redo |
| `app-crypt/ssh-profile-config` | live | Scripts to auto-configure the ssh agent and load keys/passwords |
| `app-editors/turbo` | live | Terminal text editor based on Scintilla and Turbo Vision |
| `app-misc/claude-desktop` | release | Claude AI Desktop application (unofficial Linux repackage) |
| `dev-libs/tvision` | live | Turbo Vision — a modern port of Borland's TUI library |
| `dev-util/fnm` | release | Fast and simple Node.js version manager, built in Rust |
| `dev-util/shellcheck` | release | Shell script analysis tool (built from source) |
| `kde-plasma/ksshaskpass` | stub | Dummy package to satisfy dependencies without installing anything |
| `media-fonts/nerd-fonts` | release | Fonts patched to include a high number of glyphs (icons) |
| `net-wireless/bt-keys-sync` | live | Sync Bluetooth pairing keys between Windows and Linux |
| `sys-apps/fsearch` | release | A fast file search utility for Unix-like systems |
| `sys-block/partclone` | release | Utilities to save and restore only used blocks on a partition |
| `x11-misc/polo` | live | Polo File Manager (Vala/GTK) |

*live* tracks upstream HEAD (`-9999`, empty `KEYWORDS`); *release* pins an
upstream version; *stub* is a metadata-only placeholder.

## Contributing

Bug reports and pull requests are welcome. Please read
[CONTRIBUTING.md](CONTRIBUTING.md) first.

## Authors & acknowledgements

Created and maintained by Stefano Balzarotti (OrbintSoft), with contributions from
Claude (AI assistant) and the Gentoo community. Thanks to the Gentoo project, all
contributors, and the upstream authors of the packaged software.
See [AUTHORS.md](AUTHORS.md) for the full list.

## License

The overlay's own files (ebuilds, eclasses, metadata, scripts) are distributed
under the terms of the GNU General Public License v3 — see [LICENSE](LICENSE).
Each packaged piece of software is covered by its own upstream license, as
declared in the `LICENSE` variable of the respective ebuild.
