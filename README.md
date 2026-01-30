<div align="center">
    <a href="https://teddysun.com/700.html" target="_blank">
        <img alt="LCMP" src="https://github.com/teddysun/lcmp/raw/master/conf/lcmp.png">
    </a>
</div>

## Description

LCMP (Linux + Caddy + MariaDB + PHP) is a powerful bash script for the installation of Caddy2 + MariaDB + PHP and so on.

You can install Caddy2 + MariaDB + PHP in a smaller memory VPS by `dnf` or `apt-get` command, Just need to input numbers to choose what you want to install before installation.

And all things will be done in a few minutes.

- [Supported System](#supported-system)
- [System requirements](#system-requirements)
- [Supported Software](#supported-software)
- [Supported Architecture](#supported-architecture)
- [Installation](#installation)
- [Upgrade](#upgrade)
- [Uninstall](#uninstall)
- [Default Location](#default-location)
- [Process Management](#process-management)
- [lcmp command](#lcmp-command)
- [Bugs & Issues](#bugs--issues)
- [License](#license)

## Supported System

- Enterprise Linux 8/9/10 (CentOS Stream, RHEL, Rocky Linux, AlmaLinux, Oracle Linux)
- Debian 11/12/13
- Ubuntu 20.04/22.04/24.04

## System requirements

- Hard disk space: 5 GiB
- RAM: 512 MiB
- Internet connection is required
- Correct repository
- User: root

## Supported Software

- Caddy 2 ※ Caddy package provided by [Teddysun Repository](https://dl.lamp.sh/shadowsocks/)
- MariaDB 10.11, 11.4, 11.8 ※ MariaDB packages provided by [MariaDB Repository](https://dlm.mariadb.com/browse/mariadb_server/)
- PHP 7.4, 8.0, 8.1, 8.2, 8.3, 8.4, 8.5 ※ PHP rpm packages provided by [Remi Repository](https://rpms.remirepo.net/), deb packages provided by [deb.sury.org](https://deb.sury.org/)

## Supported Architecture

- x86_64 (amd64)
- aarch64 (arm64)

## Installation

- If your server's OS: Enterprise Linux 8 / 9 / 10
```bash
dnf -y install wget git
git clone https://github.com/teddysun/lcmp.git
cd lcmp
chmod +x *.sh
./lcmp.sh
```

- If your server's OS: Debian 11 ~ 13 / Ubuntu 20.04 ~ 24.04
```bash
apt-get -y install wget git
git clone https://github.com/teddysun/lcmp.git
cd lcmp
chmod +x *.sh
./lcmp.sh
```

## Upgrade

- If your server's OS: Enterprise Linux 8 / 9 / 10
```bash
dnf update -y caddy
dnf update -y MariaDB-*
dnf update -y php-*
# Change PHP directory's group for Caddy again if you upgraded PHP version
chown root:caddy /var/lib/php/{session,wsdlcache,opcache}
```

- How to upgrade PHP **MAJOR** version in Enterprise Linux 8 / 9 / 10

Example: From PHP 8.3 to 8.4
```bash
dnf module switch-to php:remi-8.4
```

- If your server's OS: Debian 11 ~ 13 / Ubuntu 20.04 ~ 24.04
```bash
apt-get install --only-upgrade -y caddy
apt-get install --only-upgrade -y mariadb-*
# for example: php_ver=[7.4|8.0|8.1|8.2|8.3|8.4|8.5]
php_ver="8.4"
apt-get install --only-upgrade -y php${php_ver}-*
```

## Uninstall

- If your server's OS: Enterprise Linux 8 / 9 / 10
```bash
dnf remove -y caddy
dnf remove -y MariaDB-*
dnf remove -y php-*
```

- If your server's OS: Debian 11 ~ 13 / Ubuntu 20.04 ~ 24.04
```bash
apt-get remove -y caddy
apt-get remove -y mariadb-*
# for example: php_ver=[7.4|8.0|8.1|8.2|8.3|8.4|8.5]
php_ver="8.4"
apt-get remove -y php${php_ver}-*
```

## Default Location

| Caddy Location             | Path                                        |
|----------------------------|---------------------------------------------|
| Web root location          | /data/www/default                           |
| Main Configuration File    | /etc/caddy/Caddyfile                        |
| Sites Configuration Folder | /etc/caddy/conf.d/                          |

| MariaDB Location           | Path                                        |
|----------------------------|---------------------------------------------|
| Data Location              | /var/lib/mysql                              |
| my.cnf File (rpm)          | /etc/my.cnf                                 |
| my.cnf File (deb)          | /etc/mysql/my.cnf                           |

| PHP Location               | Path                                        |
|----------------------------|---------------------------------------------|
| php-fpm File (rpm)         | /etc/php-fpm.d/www.conf                     |
| php-fpm File (deb)         | /etc/php/${php_ver}/fpm/pool.d/www.conf     |
| php.ini File (rpm)         | /etc/php.ini                                |
| php.ini File (deb)         | /etc/php/${php_ver}/fpm/php.ini             |

## Process Management

| Process     | Command                                                    |
|-------------|------------------------------------------------------------|
| Caddy       | systemctl [start\|stop\|status\|restart] caddy             |
| MariaDB     | systemctl [start\|stop\|status\|restart] mariadb           |
| PHP (rpm)   | systemctl [start\|stop\|status\|restart] php-fpm           |
| PHP (deb)   | systemctl [start\|stop\|status\|restart] php${php_ver}-fpm |

## lcmp Command

| Command          | Description                                           |
|------------------|-------------------------------------------------------|
| lcmp start       | Start all of LCMP services                            |
| lcmp stop        | Stop all of LCMP services                             |
| lcmp restart     | Restart all of LCMP services                          |
| lcmp status      | Check all of LCMP services status                     |
| lcmp version     | Print all of LCMP software version                    |
| lcmp vhost add   | Create a new Caddy virtual host                       |
| lcmp vhost list  | List all of Caddy virtual hosts                       |
| lcmp vhost del   | Delete a Caddy virtual host                           |
| lcmp db add      | Create a MariaDB database and a user with same name   |
| lcmp db list     | List all of MariaDB databases                         |
| lcmp db del      | Delete a MariaDB database and a user with same name   |
| lcmp db edit     | Update a MariaDB database username's password         |

## Bugs & Issues

Please feel free to report any bugs or issues to us, email to: i@teddysun.com or [open issues](https://github.com/teddysun/lcmp/issues) on Github.


## License

Copyright (C) 2023 - 2026 [Teddysun](https://teddysun.com/)

Licensed under the [GPLv3](LICENSE) License.
