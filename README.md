# utils

Personal utils and scripts

## Scripts

### `scripts/arch-usb.sh`

Download, verify, and flash the Arch Linux ISO to a USB drive on macOS. The
checksum is fetched from archlinux.org (not the mirror), and the script refuses
to write to anything that doesn't look like an external/removable disk.

```sh
./scripts/arch-usb.sh                 # prompts for target disk
./scripts/arch-usb.sh /dev/disk4
MIRROR=https://mirror.example.com/archlinux OUT_DIR=~/Downloads ./scripts/arch-usb.sh
```

Env vars: `MIRROR` (default: mirrors.mit.edu), `VERSION` (default: `latest`),
`OUT_DIR` (default: current directory).

### `scripts/migrate-repos.sh`

Rewrite the `origin` remote URL across every git repo in a directory —
useful after a username or org rename.

```sh
./scripts/migrate-repos.sh -n olduser newuser     # dry run
./scripts/migrate-repos.sh olduser newuser
./scripts/migrate-repos.sh -d ~/work old-org new-org
```

Flags: `-n` dry run, `-d` repos directory (default: `$REPOS_DIR` or `~/repos`).

### `scripts/set-file-associations.sh`

Associate every programming-language file extension known to
[GitHub Linguist](https://github.com/github/linguist) with an app on macOS.

```sh
./scripts/set-file-associations.sh                    # default: VS Code
./scripts/set-file-associations.sh com.sublimetext.4
./scripts/set-file-associations.sh -n                 # dry run
```

Requires `duti` and `yq` (`brew install duti yq`). Env vars: `ROLE`
(default: `all`), `BUNDLE_ID` (or pass as the first argument).
