# till — Debian Environment Builder (.deb package layout)

A lightweight Bash tool for creating **per-project Debian root environments** using `mmdebstrap` and real `chroot`. By default, `till` uses a private mount namespace so bind mounts auto-unmount when you exit.

---

## 🧩 Compatibility

`till` targets **Debian-based systems** with `mmdebstrap` available.

### Supported Systems
- **Debian 11 (Bullseye)** or later  
- **Ubuntu 22.04 (Jammy)** or later  
- Popular derivatives (Linux Mint 21+, Pop!\_OS 22.04+, etc.)

### Kernel / Architecture
- Linux **≥ 4.15**
- Architectures: **amd64** (tested), **arm64** (supported if `mmdebstrap` is available)

### Core Dependencies
| Package                    | Minimum | Purpose                                        |
|---------------------------|---------|------------------------------------------------|
| `bash`                    | 5.0+    | Shell runtime                                  |
| `mmdebstrap`              | 1.0+    | Bootstraps Debian rootfs                       |
| `coreutils`, `util-linux` | system  | `mount`, `unshare`, `chroot`, and basic tools  |
| `sudo`                    | any     | Privilege escalation for build/destroy         |
| `acl`                     | any     | (Optional) grant host ↔ chroot file access     |
| `curl` **or** `wget`      | any     | (Optional) mirror probing                      |

**Notes**
- Requires **sudo** to build or destroy environments.  
- Works under normal shells; containers not required.  
- Uses `unshare -m` for private mount namespace when available.  
- Tested on **Debian Bookworm** and **Ubuntu 22.04**.

---

## 📁 Project Layout

    .
    ├── build-deb.sh                      # Helper to build the .deb package
    ├── debian-benchmark.sh               # Optional mirror benchmark script
    ├── README.md                         # This file
    ├── src/
    │   ├── DEBIAN/
    │   │   └── control                   # Debian package metadata
    │   ├── etc/
    │   │   └── till/
    │   │       └── config                # System default till configuration
    │   └── usr/
    │       ├── bin/
    │       │   └── till                  # Main till executable script
    │       └── share/
    │           └── bash-completion/
    │               └── completions/
    │                   └── till          # Bash completion for till
    └── till_0.1.0_all.deb                # Built Debian package artifact

---

## 🧩 Package Overview

**Package name:** `till`  
**Description:** Minimalist per-project Debian environment manager. It builds, enters, and destroys chroot-based environments using native Debian tools.

### Key Features
- Fast bootstraps via **mmdebstrap**  
- Per-project configs (`.till/config`, `.tillrc`) with clear precedence  
- **Auto-clean** mount namespaces using `unshare -m`  
- Bind-mounts the current directory on `enter`  
- Optional **ACL grants** so host tools can read/write files created in chroot  
- Robust config parser (tolerates spaces around `=`, strips inline `#` comments)  
- `till show-config` prints effective values *and* where each came from  
- Optional Bash completion

---

## ⚙️ Configuration

`till` reads configuration in this precedence (low → high):

1. `/etc/till/config`  
2. `~/.config/till/config`  
3. `./.tillrc`  
4. `./.till/config`

Higher entries override lower ones. You can also use environment variables such as `TILL_VERBOSE=1` and `TILL_KEYRING=/path/to/keyring.gpg`.

### Example project config (`./.till/config`)

    # ---- Core ----
    PATH=.till/debian
    RELEASE=bookworm
    MIRROR=http://deb.debian.org/debian

    # ---- Packages ----
    PACKAGES_MODE=append
    PACKAGES="git build-essential"
    # PACKAGES_FILE=.till/packages.txt

    # ---- Policy / Networking ----
    GPG_SECURE=false
    IPV4_ONLY=false

    # ---- Mount behavior ----
    MOUNT_NAMESPACE=true

    # ---- ACLs (host ↔ chroot file access) ----
    ACL_AUTO=true
    # ACL_USER=yourhostusername

### Config keys — what / why / default

- **`PATH`** (string)  
  *What:* Location of the Debian rootfs for this project.  
  *Why:* Keep the environment local to the repo; avoid collisions across projects.  
  *Default:* `$PWD/.till/debian`.

- **`RELEASE`** (string; Debian codename)  
  *What:* Debian version to bootstrap (e.g., `bookworm`, `trixie`).  
  *Why:* Choose a stable or testing userland per project.  
  *Default:* `bookworm`.

- **`MIRROR`** (URL)  
  *What:* Debian archive mirror.  
  *Why:* Faster/local mirrors speed up bootstraps and apt operations.  
  *Default:* `http://deb.debian.org/debian`.

- **`PACKAGES_MODE`** (`append`|`replace`)  
  *What:* How to combine your `PACKAGES` with built-ins.  
  *Why:* `append` adds common tools; `replace` for minimal/custom sets.  
  *Default:* `append`.

- **`PACKAGES`** (space-separated package list)  
  *What:* Extra packages to install at bootstrap time.  
  *Why:* Ensure standard tools are present right away.  
  *Default:* empty (only built-ins).

- **`PACKAGES_FILE`** (path)  
  *What:* File containing one package name per line.  
  *Why:* Easier to maintain long package lists.  
  *Default:* unset.

- **`GPG_SECURE`** (`true`|`false`)  
  *What:* Enforce apt repository signature verification.  
  *Why:* Security; set true for production/Internet mirrors.  
  *Default:* `false` (allows insecure bootstrap; useful for air-gapped/custom mirrors).  
  *Note:* When `true`, set `TILL_KEYRING=/path/to/keyring.gpg`.

- **`IPV4_ONLY`** (`true`|`false`)  
  *What:* Force apt to use IPv4 only.  
  *Why:* Workaround environments with broken IPv6.  
  *Default:* `false`.

- **`MOUNT_NAMESPACE`** (`true`|`false`)  
  *What:* Use a private mount namespace on `enter`.  
  *Why:* Auto-unmounts all bind mounts when you exit the shell.  
  *Default:* `true`.

- **`ACL_AUTO`** (`true`|`false`)  
  *What:* Automatically grant ACLs on host `$PWD` and the chroot bind target.  
  *Why:* So host tools (editors, linters) can read/write files created inside the chroot.  
  *Default:* `false`.

- **`ACL_USER`** (username)  
  *What:* User to grant rwX ACLs to.  
  *Why:* Explicit control; otherwise `till` uses `$SUDO_USER` or `$USER`.  
  *Default:* unset → falls back to `$SUDO_USER` or `$USER`.

**Show effective config and sources**
- `till show-config` (alias `till config`) prints every parameter, its value, and whether it came from defaults or a specific config file.

---

## 🔧 Installation

    # Install the package
    sudo apt install ./till_0.1.0_all.deb

    # Verify installation
    which till
    till --help
    till show-config

---

## 🧰 Usage

    till build        # bootstrap a Debian rootfs
    till enter        # enter the environment (bind-mounts $PWD by default)
    till destroy      # unmount and delete the environment
    till show-config  # show effective params + where they came from

**Examples**

    # Build + enter with defaults from ./.till/config
    till build
    till enter

    # Build with custom mirror and release
    till build --mirror http://ftp.us.debian.org/debian --release trixie

    # Enter as root and force ACL grant to a specific user
    till enter --as-root --grant-acl --acl-user yourhostusername

---

## 🪶 Bash Completion

If `bash-completion` is installed, completion is available at:

    /usr/share/bash-completion/completions/till

Load it manually (if needed):

    . /usr/share/bash-completion/completions/till

---

## 🚀 Mirror Benchmark (Optional)

A helper script can benchmark nearby Debian mirrors. Selecting the fastest mirror in your config significantly speeds up bootstrap and apt operations.

---

## 🧱 Debian Package Details

Example `src/DEBIAN/control`:

    Source: till
    Section: utils
    Priority: optional
    Maintainer: Your Name <you@example.com>
    Homepage: https://github.com/your/repo
    Standards-Version: 4.7.0
    Rules-Requires-Root: no

    Package: till
    Architecture: all
    Version: 0.1.0-1
    Depends: bash (>= 5), coreutils, util-linux, mmdebstrap, sudo, acl
    Recommends: bash-completion
    Suggests: ca-certificates, curl | wget
    Description: Tiny per-project Debian chroot manager (mmdebstrap + chroot)
     till bootstraps a minimal Debian root filesystem per project using
     mmdebstrap and provides convenient commands to enter and destroy it
     using real chroot isolation. By default it uses an unshare-based private
     mount namespace so bind mounts auto-clean when you exit.

---

## 🧹 Uninstall

    sudo apt remove till
    sudo rm -rf ~/.config/till ~/.till

---

## 🔐 Security Notes

- `till build` / `till destroy` run with elevated privileges via `sudo`. Review mirrors and package sources when `GPG_SECURE=false`.
- ACL features require `setfacl/getfacl` and a filesystem with ACL support (ext4/xfs typical).

---

## 📜 License

MIT (recommended): simple and permissive.

---

## 💡 Author

Nick Kiermaier  
Version 0.1.0
