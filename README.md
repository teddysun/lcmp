<div align="center">
    <a href="https://teddysun.com/700.html" target="_blank">
        <img alt="LCMP" src="https://github.com/teddysun/lcmp/raw/master/conf/lcmp.png" width="600">
    </a>
    <h3>🚀 LCMP - Linux + Caddy + MariaDB + PHP</h3>
    <p>A powerful bash script for automated installation of Caddy2 + MariaDB + PHP stack</p>
    <p>
        <img src="https://img.shields.io/badge/Caddy-2-00ADD8?style=flat-square&logo=caddy&logoColor=white" alt="Caddy 2">
        <img src="https://img.shields.io/badge/MariaDB-10.11|11.4|11.8-003545?style=flat-square&logo=mariadb&logoColor=white" alt="MariaDB">
        <img src="https://img.shields.io/badge/PHP-7.4~8.5-777BB4?style=flat-square&logo=php&logoColor=white" alt="PHP">
        <img src="https://img.shields.io/badge/License-GPLv3-blue.svg?style=flat-square" alt="License">
    </p>
</div>

---

## 📋 Table of Contents

- [Description](#description)
- [Supported System](#supported-system)
- [System Requirements](#system-requirements)
- [Supported Software](#supported-software)
- [Supported Architecture](#supported-architecture)
- [Installation](#installation)
- [Upgrade](#upgrade)
- [Uninstall](#uninstall)
- [Default Location](#default-location)
- [Process Management](#process-management)
- [lcmp Command](#lcmp-command)
- [Bugs & Issues](#bugs--issues)
- [License](#license)

---

## 📝 Description

**LCMP** (Linux + Caddy + MariaDB + PHP) is a powerful bash script for the installation of **Caddy2** + **MariaDB** + **PHP** stack.

✨ **Key Features:**
- One-command installation - just input numbers to select components
- Optimized for small memory VPS (512 MiB+ RAM)
- Supports both `dnf` (RHEL-based) and `apt-get` (Debian-based) package managers
- Complete installation in just a few minutes

---

## 💻 Supported System

| Distribution | Versions |
|-------------|----------|
| **Enterprise Linux** | 8 / 9 / 10 (CentOS Stream, RHEL, Rocky Linux, AlmaLinux, Oracle Linux) |
| **Debian** | 11 / 12 / 13 |
| **Ubuntu** | 20.04 / 22.04 / 24.04 |

---

## ⚙️ System Requirements

| Requirement | Minimum |
|-------------|---------|
| Disk Space | 5 GiB |
| RAM | 512 MiB |
| Network | Internet connection required |
| Repository | Correct system repository |
| User | root |

---

## 🛠️ Supported Software

| Software | Versions | Package Source |
|----------|----------|----------------|
| **Caddy** | 2 | [Teddysun Repository](https://dl.lamp.sh/shadowsocks/) |
| **MariaDB** | 10.11, 11.4, 11.8 | [MariaDB Repository](https://dlm.mariadb.com/browse/mariadb_server/) |
| **PHP** | 7.4, 8.0, 8.1, 8.2, 8.3, 8.4, 8.5 | [Remi Repository](https://rpms.remirepo.net/) (RPM) / [deb.sury.org](https://deb.sury.org/) (DEB) |

---

## 🏗️ Supported Architecture

- `x86_64` (amd64)
- `aarch64` (arm64)

---

## 🚀 Installation

### Enterprise Linux 8 / 9 / 10

```bash
dnf -y install wget git
git clone https://github.com/teddysun/lcmp.git
cd lcmp
chmod +x *.sh
./lcmp.sh
```

### Debian 11 ~ 13 / Ubuntu 20.04 ~ 24.04

```bash
apt-get -y install wget git
git clone https://github.com/teddysun/lcmp.git
cd lcmp
chmod +x *.sh
./lcmp.sh
```

---

## ⬆️ Upgrade

### Enterprise Linux 8 / 9 / 10

```bash
# Upgrade individual components
dnf update -y caddy
dnf update -y MariaDB-*
dnf update -y php-*

# Important: Fix PHP directory permissions after PHP version upgrade
chown root:caddy /var/lib/php/{session,wsdlcache,opcache}
```

#### Upgrade PHP Major Version (e.g., 8.3 → 8.4)

```bash
dnf module switch-to php:remi-8.4
```

### Debian 11 ~ 13 / Ubuntu 20.04 ~ 24.04

```bash
# Upgrade individual components
apt-get install --only-upgrade -y caddy
apt-get install --only-upgrade -y mariadb-*

# Upgrade PHP (replace 8.4 with your version: 7.4|8.0|8.1|8.2|8.3|8.4|8.5)
php_ver="8.4"
apt-get install --only-upgrade -y php${php_ver}-*
```

---

## 🗑️ Uninstall

### Enterprise Linux 8 / 9 / 10

```bash
dnf remove -y caddy
dnf remove -y MariaDB-*
dnf remove -y php-*
```

### Debian 11 ~ 13 / Ubuntu 20.04 ~ 24.04

```bash
apt-get remove -y caddy
apt-get remove -y mariadb-*

# Remove PHP (replace 8.4 with your version: 7.4|8.0|8.1|8.2|8.3|8.4|8.5)
php_ver="8.4"
apt-get remove -y php${php_ver}-*
```

---

## 📁 Default Location

### Caddy

| Item | Path |
|------|------|
| Web root | `/data/www/default` |
| Main config | `/etc/caddy/Caddyfile` |
| Sites config | `/etc/caddy/conf.d/` |

### MariaDB

| Item | Path |
|------|------|
| Data directory | `/var/lib/mysql` |
| Config (RPM) | `/etc/my.cnf` |
| Config (DEB) | `/etc/mysql/my.cnf` |

### PHP

| Item | Path |
|------|------|
| php-fpm (RPM) | `/etc/php-fpm.d/www.conf` |
| php-fpm (DEB) | `/etc/php/${php_ver}/fpm/pool.d/www.conf` |
| php.ini (RPM) | `/etc/php.ini` |
| php.ini (DEB) | `/etc/php/${php_ver}/fpm/php.ini` |

---

## 🔧 Process Management

| Service | Command |
|---------|---------|
| Caddy | `systemctl [start\|stop\|status\|restart] caddy` |
| MariaDB | `systemctl [start\|stop\|status\|restart] mariadb` |
| PHP (RPM) | `systemctl [start\|stop\|status\|restart] php-fpm` |
| PHP (DEB) | `systemctl [start\|stop\|status\|restart] php${php_ver}-fpm` |

---

## ⌨️ lcmp Command

| Command | Description |
|---------|-------------|
| `lcmp start` | Start all LCMP services |
| `lcmp stop` | Stop all LCMP services |
| `lcmp restart` | Restart all LCMP services |
| `lcmp status` | Check all LCMP services status |
| `lcmp version` | Print all LCMP software versions |
| `lcmp vhost add` | Create a new Caddy virtual host |
| `lcmp vhost list` | List all Caddy virtual hosts |
| `lcmp vhost del` | Delete a Caddy virtual host |
| `lcmp db add` | Create a MariaDB database and user |
| `lcmp db list` | List all MariaDB databases |
| `lcmp db del` | Delete a MariaDB database and user |
| `lcmp db edit` | Update a MariaDB user's password |

---

## 🐛 Bugs & Issues

Please feel free to report any bugs or issues:

- 📧 Email: [i@teddysun.com](mailto:i@teddysun.com)
- 🐙 GitHub: [Open an Issue](https://github.com/teddysun/lcmp/issues)

---

## 📄 License

Copyright (C) 2023 - 2026 [Teddysun](https://teddysun.com/)

Licensed under the [GPLv3](LICENSE) License.
