# till — tiny per-project Debian environments (CHROOT edition)

`till` is a lightweight Bash tool for creating disposable per-project Debian root filesystems using **mmdebstrap** and **real chroot** — no containers, no virtualization, just isolated environments built in directories.

---

## Features

- Real Debian rootfs (no Docker required)  
- Automatic cleanup using private mount namespaces (`unshare -m`)  
- Configurable package sets per project  
- Safe destruction and rebuild  
- Works offline once bootstrapped  

---

## Commands

| Command | Description |
|----------|-------------|
| `till build` | Bootstrap a Debian rootfs (requires sudo). |
| `till enter` | Enter the rootfs; optionally bind-mount the current working directory. |
| `till destroy` | Unmount and delete the environment. |

---

## Installation

```bash
sudo install -m 0755 till /usr/local/bin/till
till --help
```

---

## Quick Start

```bash
# Create a minimal Debian environment in ./.till/debian
till build

# Enter it (bind-mounts your current working directory by default)
till enter

# Destroy when done
till destroy
```

---

## Configuration

`till` reads configuration from these locations (highest precedence first):

1. `./.till/config`  
2. `./.tillrc`  
3. `~/.config/till/config`  
4. `/etc/till/config`

Example configuration file (`~/.config/till/config`):

```ini
# Rootfs location
PATH=.till/debian

# Debian release codename
RELEASE=bookworm

# Mirror URL
MIRROR=http://deb.debian.org/debian

# Package handling: append or replace built-ins
PACKAGES_MODE=append
PACKAGES="git build-essential"

# Networking & security
GPG_SECURE=false
IPV4_ONLY=false

# Namespace mode
MOUNT_NAMESPACE=true
```

Environment variables:

| Variable | Description |
|-----------|--------------|
| `TILL_VERBOSE=1` | Enable verbose mode. |
| `TILL_KEYRING=/path/to/keyring.gpg` | Used when `GPG_SECURE=true`. |

---

## Command Reference

### Build

```bash
till build [--path PATH] [--release REL] [--mirror URL]
           [--packages "pkg1 pkg2"] [--packages-file FILE]
           [--packages-mode append|replace] [--verbose]
```

- Bootstraps a new Debian environment using `mmdebstrap`.
- Default includes core utilities like `bash`, `coreutils`, `sudo`, `vim-tiny`, etc.

Example:

```bash
till build --release trixie --packages "git curl make"
```

---

### Enter

```bash
till enter [--path PATH] [--no-bind-pwd] [--as-root]
           [--no-ns] [--verbose]
```

- Starts a shell inside the chroot.
- By default, uses a private mount namespace that cleans up automatically when you exit.

Example:

```bash
till enter --as-root
```

---

### Destroy

```bash
till destroy [--path PATH] [--force] [--verbose]
```

- Unmounts all mounts and deletes the rootfs directory.

Example:

```bash
till destroy --force
```

---

## How It Works

- **Build** — Runs `mmdebstrap --mode=root` with selected packages.  
  Creates `/usr/sbin/policy-rc.d` inside the chroot to prevent services from starting.
- **Enter** — Uses `unshare -m` for auto-cleanup or legacy mounts with traps.
- **Destroy** — Unmounts and deletes everything under the environment path.

---

## Notes

- Uses `/etc/skel` for default `.bashrc` and `.profile` if none provided.
- IPv6 can be disabled via `IPV4_ONLY=true`.
- To enforce apt signature verification, set `GPG_SECURE=true` and provide `TILL_KEYRING`.

---

## Requirements

- Debian / Ubuntu host  
- `mmdebstrap`, `util-linux`, `coreutils`, `sudo`, `mount`, `bash >= 5`  
- Optional: `curl` or `wget` for mirror probe

---

## License
MIT

