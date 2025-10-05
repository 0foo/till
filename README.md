# till
*A tiny Debian chroot manager for per-project environments*

`till` makes it easy to create isolated Debian environments per project — using only `debootstrap` and `chroot`.  
You can build and enter a full Debian root filesystem without containers, VMs, or mounts.

---

## Features

- 🧱 **Create self-contained Debian roots** with `till build`
- 🔗 **Enter** environments with `till enter`, bind-mounting your current working directory
- ⚙️ **Configurable** via per-project or global config files
- 💼 **Portable** — works anywhere on Debian-based systems
- 🧩 **Custom package sets** via config or CLI

---

## Installation

### From `.deb` file

```bash
sudo apt install ./till_1.0.0-2.deb
```

This installs:

- `/usr/bin/till`
- `/usr/share/bash-completion/completions/till`
- `/etc/till/config`

### From source

```bash
sudo install -m 0755 till /usr/bin/till
sudo install -Dm0644 completions/till /usr/share/bash-completion/completions/till
sudo install -Dm0644 etc/till/config /etc/till/config
```

---

## Basic Usage

```bash
till build             # Bootstrap Debian root at ./.till/debian
till enter             # Enter it, bind-mounting current directory
till enter --as-root   # Enter as root inside the chroot
till build --path ~/envs/projA --packages "git python3"
```

When entering, your user ID and group ID are mapped so files created inside the chroot belong to you on the host.  
Use `--as-root` to perform administrative tasks within the chroot (e.g. creating users, editing `/etc`).

---

## Configuration

`till` loads configuration from the following locations, in order of precedence:

1. `./.till/config`  
2. `./.tillrc`  
3. `~/.config/till/config`  
4. `/etc/till/config`

Example `./.till/config`:

```ini
# Path where the chroot will be created
PATH=.till/debian

# Debian release to use
RELEASE=bookworm

# Debian mirror to use
MIRROR=http://deb.debian.org/debian

# append (default) = add to default tools
# replace = use only the packages below
PACKAGES_MODE=append

# Extra packages to install
PACKAGES="git make python3 python3-venv"

# Optional: external package list file
PACKAGES_FILE=.till/packages.txt
```

`.till/packages.txt`:

```
# one per line, comments allowed
ripgrep
fd-find
htop
```

---

## Command Reference

### `till build`

Bootstraps a Debian environment at the configured path.  
Installs common utilities and any extra packages from your config.

Options:

| Option | Description |
|---------|-------------|
| `--path` | Location of the chroot (default `.till/debian`) |
| `--release` | Debian codename (default `bookworm`) |
| `--mirror` | Mirror URL (default `http://deb.debian.org/debian`) |
| `--packages` | Space-separated list of packages to install |
| `--packages-file` | Path to a file with one package per line |
| `--packages-mode` | `append` or `replace` (default `append`) |

### `till enter`

Enters the environment (bind-mounts your current directory by default).

Options:

| Option | Description |
|---------|-------------|
| `--path` | Location of the chroot |
| `--no-bind-pwd` | Do not bind-mount current working directory |
| `--as-root` | Enter as root instead of your own UID/GID |

---

## Example Workflow

```bash
# 1. Initialize environment
till build

# 2. Enter it
till enter

# 3. Inside, install or run whatever you want
apt install gcc
exit

# 4. Enter again later
till enter
```

---

## Configuration Hierarchy

| Level | Path | Purpose |
|--------|------|----------|
| System | `/etc/till/config` | Organization-wide defaults |
| User | `~/.config/till/config` | Personal defaults |
| Project | `./.till/config` or `./.tillrc` | Per-project overrides |

---

## Default System Config

`/etc/till/config`:

```ini
RELEASE=bookworm
MIRROR=http://deb.debian.org/debian
PACKAGES_MODE=append
PACKAGES="git build-essential"
```

---

## Notes

- No `/proc`, `/sys`, or `/dev/pts` mounts are used by default (for safety).  
  Add them manually if needed.
- Uses your user UID/GID for normal sessions, preventing root-owned files on your host.
- Fully self-contained — delete the environment directory to remove it.

---

## License

MIT

