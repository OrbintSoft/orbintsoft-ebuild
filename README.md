# orbintsoft-ebuild

A personal [Gentoo](https://www.gentoo.org/) overlay maintained by Stefano
Balzarotti / OrbintSoft. It ships ebuilds for software that is not in the main
Gentoo tree, or for variants of it.

- **EAPI:** 8 · **masters:** `gentoo` · **manifests:** thin
- **Repository name:** `orbintsoft`
- **License:** [GPL-3.0](LICENSE) for the overlay's own files (each packaged
  program keeps its own upstream license, declared per ebuild)

> ⚠️ This is a personal overlay. Most ebuilds are **live** (`-9999`) and track
> upstream `master`/`main`. Treat it as work in progress; see [PLAN.md](PLAN.md)
> for the quality roadmap.

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
Live (`-9999`) ebuilds have empty `KEYWORDS` and may need to be unmasked first.

## Packages

| Package | Description |
|---|---|
| `app-admin/pamtester` | Non-interactive PAM testing tool |
| `app-backup/redo-backups` | Create backups compatible with redo |
| `app-crypt/ssh-profile-config` | Scripts to auto-configure the ssh agent and load keys/passwords |
| `app-misc/claude-desktop` | Claude AI Desktop application (unofficial Linux repackage) |
| `dev-libs/tvision` | Turbo Vision — a modern port of Borland's TUI library |
| `dev-util/fnm` | Fast and simple Node.js version manager, built in Rust |
| `dev-util/shellcheck` | Shell script analysis tool (built from source) |
| `kde-plasma/ksshaskpass` | Dummy package to satisfy dependencies without installing anything |
| `media-fonts/nerd-fonts` | Fonts patched to include a high number of glyphs (icons) |
| `net-wireless/bt-keys-sync` | Sync Bluetooth pairing keys between Windows and Linux |
| `sys-apps/fsearch` | A fast file search utility for Unix-like systems |
| `x11-misc/polo` | Polo File Manager (Vala/GTK) |

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
