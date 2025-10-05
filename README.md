# till — Debian Environment Builder (.deb package layout)

— a lightweight Bash tool for creating isolated Debian root environments using `mmdebstrap` and `chroot`.

---

## Compatibility
* This has only been tested on Ubuntu 22.04
* Theoretically should work on any Debian system
* There's ways to make it more cross compatible by using other flavors of debootstrap
  * other options are: dbootstrap, cdebootstrap, mmdebstrap, or multistrap
  * This project currently uses mmbootstrap which only works on Debian

## 📁 Project Layout

```
.
├── build-deb.sh                # Build helper to create the .deb package
├── debian-benchmark.sh         # Optional benchmark/test script
├── README.md                   # This file
├── src/
│   ├── DEBIAN/
│   │   └── control             # Debian package metadata
│   ├── etc/
│   │   └── till/
│   │       └── config          # Default till configuration
│   └── usr/
│       ├── bin/
│       │   └── till            # Main till executable script
│       └── share/
│           └── bash-completion/
│               └── completions/
│                   └── till    # Bash completion file for till
└── till_0.1.0_all.deb          # Built Debian package artifact
```

---

## 🧩 Package Overview

### Package Name
`Till`

### Description
`till` is a minimalist per-project Debian environment manager. It builds, enters, and destroys chroot-based environments using native Debian tools.

### Key Features
- Uses **mmdebstrap** for fast bootstraps  
- Supports **per-project configs** (`.till/config`, `.tillrc`)  
- **Auto-clean** mount namespaces using `unshare -m`  
- Can bind-mount the current directory  
- **System-wide**, **user**, and **project-level** configs  
- Optional **bash-completion** integration

---

## ⚙️ Configuration

Default config file installed at:
```
/etc/till/config
```

Example:
```ini
PATH=.till/debian
RELEASE=bookworm
MIRROR=http://deb.debian.org/debian
PACKAGES_MODE=append
PACKAGES="git build-essential"
GPG_SECURE=false
IPV4_ONLY=false
MOUNT_NAMESPACE=true
```

---

## 🔧 Installation

```bash
# install it
sudo apt install ./till_0.1.0_all.deb

# verify installation
which till
till --help
```

---

## 🧰 Usage

```bash
till build      # bootstrap a Debian rootfs
till enter      # enter the environment
till destroy    # this is an emergency way to remove the .till folder if all else fails, should generally be able to remove it with rm -rf
```

**Examples:**
```bash
till build 
till enter 
```

---

## 🪶 Bash Completion

Once installed, shell completion will auto-enable on most systems:
```bash
source /usr/share/bash-completion/completions/till
```

To enable manually:
```bash
. /usr/share/bash-completion/completions/till
```

---
### Debian Benchmark script
* There's a benchmark script to find the quickest debian mirror next to you
* It's a HUGE help 
* Put the fastest one in the config file will speed things up


## 🧱 Debian Package Details

`src/DEBIAN/control` defines the metadata, example:

```
Package: till
Version: 0.1.0
Section: utils
Priority: optional
Architecture: all
Maintainer: Your Name <you@example.com>
Description: Tiny per-project Debian chroot environments
 till is a script that lets you quickly build, enter, and destroy
 self-contained Debian rootfs environments for project isolation.
```



---

## 🧹 Uninstall

```bash
sudo apt remove till
sudo rm -rf ~/.config/till ~/.till
```

---

## 📜 License

MIT License (recommended) — simple and permissive.

---

## 🧠 Notes

- Designed for Debian/Ubuntu systems  
- Requires: `mmdebstrap`, `sudo`, `mount`, `bash (>=5)`  which should be installed with package manager
- Optional: `curl` or `wget` for mirror probing  
- `till` environments share the host kernel but isolate userland packages  

---

## 💡 Author

Nick Kiermaier
Version 0.1.0
