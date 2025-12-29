#!/bin/bash
#
# This is a Shell script for VPS initialization and
# LCMP (Linux + Caddy + MariaDB + PHP) installation
#
# Supported OS:
# Enterprise Linux 8 (CentOS Stream 8, RHEL 8, Rocky Linux 8, AlmaLinux 8, Oracle Linux 8)
# Enterprise Linux 9 (CentOS Stream 9, RHEL 9, Rocky Linux 9, AlmaLinux 9, Oracle Linux 9)
# Enterprise Linux 10 (CentOS Stream 10, RHEL 10, Rocky Linux 10, AlmaLinux 10, Oracle Linux 10)
# Debian 11
# Debian 12
# Debian 13
# Ubuntu 20.04
# Ubuntu 22.04
# Ubuntu 24.04
#
# Copyright (C) 2023 - 2025 Teddysun <i@teddysun.com>

# Trap interrupt signals
trap _exit INT QUIT TERM

# Get the current directory of the script
cur_dir="$(cd -P -- "$(dirname -- "$0")" && pwd -P)"

# Color output functions
_red() {
    printf '\033[1;31m%b\033[0m' "$1"
}

_green() {
    printf '\033[1;32m%b\033[0m' "$1"
}

_yellow() {
    printf '\033[1;33m%b\033[0m' "$1"
}

# Print arguments with timestamp
_printargs() {
    printf -- "%s" "[$(date)] "
    printf -- "%s" "$1"
    printf "\n"
}

# Info message
_info() {
    _printargs "$@"
}

# Warning message
_warn() {
    printf -- "%s" "[$(date)] "
    _yellow "$1"
    printf "\n"
}

# Error message and exit
_error() {
    printf -- "%s" "[$(date)] "
    _red "$1"
    printf "\n"
    exit 2
}

# Exit handler
_exit() {
    printf "\n"
    _red "$0 has been terminated."
    printf "\n"
    exit 1
}

# Check if a command exists
_exists() {
    local cmd="$1"
    if eval type type >/dev/null 2>&1; then
        eval type "$cmd" >/dev/null 2>&1
    elif command >/dev/null 2>&1; then
        command -v "$cmd" >/dev/null 2>&1
    else
        which "$cmd" >/dev/null 2>&1
    fi
    local rt=$?
    return ${rt}
}

# Detect command execution errors
_error_detect() {
    local cmd="$1"
    _info "${cmd}"
    if ! eval "${cmd}" 1>/dev/null; then
        _error "Command execution failed: ${cmd}, Please check and try again."
    fi
}

# Check the operating system
check_sys() {
    local value="$1"
    local release=''
    if [ -f /etc/redhat-release ]; then
        release="rhel"
    elif grep -Eqi "debian" /etc/issue; then
        release="debian"
    elif grep -Eqi "ubuntu" /etc/issue; then
        release="ubuntu"
    elif grep -Eqi "centos|red hat|redhat" /etc/issue; then
        release="rhel"
    elif grep -Eqi "debian" /proc/version; then
        release="debian"
    elif grep -Eqi "ubuntu" /proc/version; then
        release="ubuntu"
    elif grep -Eqi "centos|red hat|redhat" /proc/version; then
        release="rhel"
    fi
    if [ "${value}" == "${release}" ]; then
        return 0
    else
        return 1
    fi
}

# Get OS information
get_opsy() {
    [ -f /etc/redhat-release ] && awk '{print $0}' /etc/redhat-release && return
    [ -f /etc/os-release ] && awk -F'[= "]' '/PRETTY_NAME/{print $3,$4,$5}' /etc/os-release && return
    [ -f /etc/lsb-release ] && awk -F'[="]+' '/DESCRIPTION/{print $2}' /etc/lsb-release && return
}

# Get RHEL version
get_rhelversion() {
    if check_sys rhel; then
        local version
        local code=$1
        local main_ver
        version=$(get_opsy)
        main_ver=$(echo "${version}" | grep -oE "[0-9.]+")
        if [ "${main_ver%%.*}" == "${code}" ]; then
            return 0
        else
            return 1
        fi
    else
        return 1
    fi
}

# Get Debian version
get_debianversion() {
    if check_sys debian; then
        local version
        local code=$1
        local main_ver
        version=$(get_opsy)
        main_ver=$(echo "${version}" | grep -oE "[0-9.]+")
        if [ "${main_ver%%.*}" == "${code}" ]; then
            return 0
        else
            return 1
        fi
    else
        return 1
    fi
}

# Get Ubuntu version
get_ubuntuversion() {
    if check_sys ubuntu; then
        local version
        local code=$1
        version=$(get_opsy)
        if echo "${version}" | grep -q "${code}"; then
            return 0
        else
            return 1
        fi
    else
        return 1
    fi
}

get_char() {
    SAVEDSTTY=$(stty -g)
    stty -echo
    stty cbreak
    dd if=/dev/tty bs=1 count=1 2>/dev/null
    stty -raw
    stty echo
    stty "${SAVEDSTTY}"
}

get_rhel_extra_repo() {
    local ver=$1
    case "$ver" in
        8) echo "powertools" ;;
        9|10) echo "crb" ;;
        *) _error "Undefined RHEL version" ;;
    esac
}

version_ge() {
    test "$(echo "$@" | tr " " "\n" | sort -rV | head -n 1)" == "$1"
}

# Check kernel version
check_kernel_version() {
    local kernel_version
    kernel_version=$(uname -r | cut -d- -f1)
    if version_ge "${kernel_version}" 4.9; then
        return 0
    else
        return 1
    fi
}

# Check BBR status
check_bbr_status() {
    local param
    param=$(sysctl net.ipv4.tcp_congestion_control | awk '{print $3}')
    if [[ "${param}" == "bbr" ]]; then
        return 0
    else
        return 1
    fi
}

set_rhel_inputrc() {
    local ver=$1
    case "$ver" in
        9|10)
            if ! grep -q "set enable-bracketed-paste off" /etc/inputrc; then
                _error_detect "echo \"set enable-bracketed-paste off\" >>/etc/inputrc"
            fi
            ;;
        *)
            # Do nothing
            ;;
    esac
}

initialize_rhel() {
    local rhel_ver
    if get_rhelversion 8; then
        rhel_ver=8
    elif get_rhelversion 9; then
        rhel_ver=9
    elif get_rhelversion 10; then
        rhel_ver=10
    else
        _error "Unsupported RHEL version"
    fi

    _error_detect "dnf install -yq https://dl.fedoraproject.org/pub/epel/epel-release-latest-${rhel_ver}.noarch.rpm"
    if _exists "subscription-manager"; then
        _error_detect "subscription-manager repos --enable codeready-builder-for-rhel-${rhel_ver}-$(arch)-rpms"
    elif [ -s "/etc/yum.repos.d/oracle-linux-ol${rhel_ver}.repo" ]; then
        _error_detect "dnf config-manager --set-enabled ol${rhel_ver}_codeready_builder"
    else
        _error_detect "dnf config-manager --set-enabled $(get_rhel_extra_repo ${rhel_ver})"
    fi
    set_rhel_inputrc ${rhel_ver}
    _error_detect "dnf install -yq https://dl.lamp.sh/linux/rhel/el${rhel_ver}/x86_64/teddysun-release-1.0-1.el${rhel_ver}.noarch.rpm"

    _error_detect "dnf makecache"
    _error_detect "dnf install -yq vim nano tar zip unzip net-tools screen git virt-what wget mtr traceroute iftop htop jq tree"
    _error_detect "dnf install -yq libnghttp2 libnghttp2-devel c-ares c-ares-devel curl libcurl libcurl-devel"
    # Handle SELinux
    if [ -s "/etc/selinux/config" ] && grep -q 'SELINUX=enforcing' /etc/selinux/config; then
        sed -i 's/^SELINUX=.*/SELINUX=disabled/g' /etc/selinux/config
        setenforce 0
        _info "Disabled SELinux"
    fi
    # Remove cockpit related file
    if [ -s "/etc/motd.d/cockpit" ]; then
        rm -f /etc/motd.d/cockpit
        _info "Deleted /etc/motd.d/cockpit"
    fi
    if systemctl status firewalld >/dev/null 2>&1; then
        default_zone="$(firewall-cmd --get-default-zone)"
        firewall-cmd --permanent --add-service=https --zone="${default_zone}" >/dev/null 2>&1
        firewall-cmd --permanent --add-service=http --zone="${default_zone}" >/dev/null 2>&1
        # Enabled udp 443 port for Caddy HTTP/3 feature
        firewall-cmd --permanent --zone="${default_zone}" --add-port=443/udp >/dev/null 2>&1
        firewall-cmd --reload >/dev/null 2>&1
        sed -i 's/AllowZoneDrifting=yes/AllowZoneDrifting=no/' /etc/firewalld/firewalld.conf
        _error_detect "systemctl restart firewalld"
        _info "Firewall configured"
    else
        _warn "firewalld is not running, skipped firewall configuration"
    fi
}

initialize_deb() {
    _error_detect "apt-get update"
    _error_detect "apt-get -yq install lsb-release ca-certificates curl gnupg"
    _error_detect "apt-get -yq install vim nano tar zip unzip net-tools screen git virt-what wget mtr traceroute iftop htop jq tree"
    if ufw status >/dev/null 2>&1; then
        _error_detect "ufw allow http"
        _error_detect "ufw allow https"
        _error_detect "ufw allow 443/udp"
    else
        _warn "ufw is not running, skipped firewall configuration"
    fi
}

initialize_system() {
    if check_sys rhel; then
        initialize_rhel
    elif check_sys debian || check_sys ubuntu; then
        initialize_deb
    else
        _error "Unsupported OS"
    fi
}

# Configure BBR
configure_bbr() {
    if check_kernel_version; then
        if ! check_bbr_status; then
            sed -i '/net.core.default_qdisc/d' /etc/sysctl.conf
            sed -i '/net.ipv4.tcp_congestion_control/d' /etc/sysctl.conf
            sed -i '/net.core.rmem_max/d' /etc/sysctl.conf
            cat >>"/etc/sysctl.conf" <<EOF
net.core.default_qdisc = fq
net.ipv4.tcp_congestion_control = bbr
net.core.rmem_max = 2500000
EOF
            sysctl -p >/dev/null 2>&1
            _info "BBR configured"
        else
            _info "BBR is already enabled, skipped configuration"
        fi
    else
        _warn "Kernel version is below 4.9, skipped BBR configuration"
    fi
}

# Configure systemd-journald
configure_journald() {
    local journald_config
    if systemctl status systemd-journald >/dev/null 2>&1; then
        if [ -s "/etc/systemd/journald.conf" ]; then
            journald_config="/etc/systemd/journald.conf"
        elif [ -s "/usr/lib/systemd/journald.conf" ]; then
            journald_config="/usr/lib/systemd/journald.conf"
        fi
        sed -i 's/^#\?Storage=.*/Storage=volatile/' ${journald_config}
        sed -i 's/^#\?SystemMaxUse=.*/SystemMaxUse=16M/' ${journald_config}
        sed -i 's/^#\?RuntimeMaxUse=.*/RuntimeMaxUse=16M/' ${journald_config}
        _error_detect "systemctl restart systemd-journald"
        _info "systemd-journald configuration completed"
    fi
}

# Check if the script is run as root
[ ${EUID} -ne 0 ] && _red "This script must be run as root!\n" && exit 1

# Check OS support
if ! get_rhelversion 8 && ! get_rhelversion 9 && ! get_rhelversion 10 &&
   ! get_debianversion 11 && ! get_debianversion 12 && ! get_debianversion 13 &&
   ! get_ubuntuversion 20.04 && ! get_ubuntuversion 22.04 && ! get_ubuntuversion 24.04; then
    _error "Unsupported OS. Please switch to Enterprise Linux 8+, Debian 11+, or Ubuntu 20.04+ and try again."
fi

# Choose MariaDB version
while true; do
    _info "Please choose a version of MariaDB:"
    _info "$(_green 1). MariaDB 10.11"
    _info "$(_green 2). MariaDB 11.4"
    _info "$(_green 3). MariaDB 11.8"
    read -r -p "[$(date)] Please input a number: (Default 2) " mariadb_version
    [ -z "${mariadb_version}" ] && mariadb_version=2
    case "${mariadb_version}" in
    1)
        mariadb_ver="10.11"
        break
        ;;
    2)
        mariadb_ver="11.4"
        break
        ;;
    3)
        mariadb_ver="11.8"
        break
        ;;
    *)
        _info "Input error. Please input a number between 1 and 3"
        ;;
    esac
done
_info "---------------------------"
_info "MariaDB version = $(_red "${mariadb_ver}")"
_info "---------------------------"

# Set MariaDB root password
_info "Please input the root password of MariaDB:"
read -s -r -p "[$(date)] (Default password: Teddysun.com) (password will not shown):" db_pass
if [ -z "${db_pass}" ]; then
    db_pass="Teddysun.com"
fi
echo
_info "---------------------------"
_info "Password = $(_red "${db_pass}")"
_info "---------------------------"

# Choose PHP version
while true; do
    _info "Please choose a version of PHP:"
    _info "$(_green 1). PHP 7.4"
    _info "$(_green 2). PHP 8.0"
    _info "$(_green 3). PHP 8.1"
    _info "$(_green 4). PHP 8.2"
    _info "$(_green 5). PHP 8.3"
    _info "$(_green 6). PHP 8.4"
    read -r -p "[$(date)] Please input a number: (Default 6) " php_version
    [ -z "${php_version}" ] && php_version=6
    case "${php_version}" in
    1)
        php_ver="7.4"
        break
        ;;
    2)
        php_ver="8.0"
        break
        ;;
    3)
        php_ver="8.1"
        break
        ;;
    4)
        php_ver="8.2"
        break
        ;;
    5)
        php_ver="8.3"
        break
        ;;
    6)
        php_ver="8.4"
        break
        ;;
    *)
        _info "Input error. Please input a number between 1 and 6"
        ;;
    esac
done
_info "---------------------------"
_info "PHP version = $(_red "${php_ver}")"
_info "---------------------------"

# Prompt user to start or cancel
_info "Press any key to start... or Press Ctrl+C to cancel"
char=$(get_char)

_info "Initialization start"
configure_bbr
configure_journald
initialize_system
echo
netstat -nxtulpe
echo
_info "Initialization completed"
sleep 3
clear
_info "LCMP (Linux + Caddy + MariaDB + PHP) installation start"
if check_sys rhel; then
    _error_detect "dnf install -yq caddy"
elif check_sys debian || check_sys ubuntu; then
    _error_detect "curl -fsSL https://dl.lamp.sh/shadowsocks/DEB-GPG-KEY-Teddysun | gpg --dearmor --yes -o /usr/share/keyrings/deb-gpg-key-teddysun.gpg"
    _error_detect "chmod a+r /usr/share/keyrings/deb-gpg-key-teddysun.gpg"
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/deb-gpg-key-teddysun.gpg] https://dl.lamp.sh/shadowsocks/$(lsb_release -si | tr '[A-Z]' '[a-z]')/ $(lsb_release -sc) main" >/etc/apt/sources.list.d/teddysun.list
    _error_detect "apt-get update"
    _error_detect "apt-get install -y caddy"
fi
_info "Caddy installation completed"

_error_detect "mkdir -p /data/www/default"
_error_detect "mkdir -p /var/log/caddy/"
_error_detect "mkdir -p /etc/caddy/conf.d/"
_error_detect "chown -R caddy:caddy /var/log/caddy/"
cat >"/etc/caddy/Caddyfile" <<EOF
{
	admin off
}
import /etc/caddy/conf.d/*.conf
EOF
_error_detect "cp -f ${cur_dir}/conf/favicon.ico /data/www/default/"
_error_detect "cp -f ${cur_dir}/conf/index.html /data/www/default/"
_error_detect "cp -f ${cur_dir}/conf/lcmp.png /data/www/default/"
_info "Caddy configuration completed"

_info "Downloading and running MariaDB repository setup script"
_error_detect "curl -sLo mariadb_repo_setup.sh https://dl.lamp.sh/files/mariadb_repo_setup.sh"
_error_detect "chmod +x mariadb_repo_setup.sh"
# Fix MariaDB package signing key import error
if get_rhelversion 10; then
    if _exists "update-crypto-policies"; then
        _error_detect "update-crypto-policies --set LEGACY"
    fi
fi
_info "./mariadb_repo_setup.sh --mariadb-server-version=mariadb-${mariadb_ver}"
./mariadb_repo_setup.sh --mariadb-server-version=mariadb-${mariadb_ver} >/dev/null 2>&1
_error_detect "rm -f mariadb_repo_setup.sh"
if check_sys rhel; then
    _error_detect "dnf config-manager --disable mariadb-maxscale"
    _error_detect "dnf install -y MariaDB-common MariaDB-server MariaDB-client MariaDB-shared MariaDB-backup"
    mariadb_cnf="/etc/my.cnf.d/server.cnf"
elif check_sys debian || check_sys ubuntu; then
    if [ -f "/etc/apt/sources.list.d/mariadb.list" ]; then
        # MariaDB MaxScale has been disabled by default because the public key is not available
        sed -i 's|^deb \[arch=amd64,arm64\] https://dlm.mariadb.com/repo/maxscale/latest/apt|#&|' /etc/apt/sources.list.d/mariadb.list
    fi
    _error_detect "apt-get update"
    _error_detect "apt-get install -y mariadb-common mariadb-server mariadb-client mariadb-backup"
    mariadb_cnf="/etc/mysql/mariadb.conf.d/50-server.cnf"
fi
_info "MariaDB installation completed"

lnum=$(sed -n '/\[mysqld\]/=' "${mariadb_cnf}")
[ -n "${lnum}" ] && sed -i "${lnum}ainnodb_buffer_pool_size = 100M\nmax_allowed_packet = 1024M\nnet_read_timeout = 3600\nnet_write_timeout = 3600" "${mariadb_cnf}"
lnum=$(sed -n '/\[mariadb\]/=' "${mariadb_cnf}" | tail -1)
[ -n "${lnum}" ] && sed -i "${lnum}acharacter-set-server = utf8mb4\n\n\[client-mariadb\]\ndefault-character-set = utf8mb4" "${mariadb_cnf}"
_error_detect "systemctl start mariadb"
sleep 3
/usr/bin/mariadb -e "grant all privileges on *.* to root@'127.0.0.1' identified by \"${db_pass}\" with grant option;"
/usr/bin/mariadb -e "grant all privileges on *.* to root@'localhost' identified by \"${db_pass}\" with grant option;"
/usr/bin/mariadb -uroot -p"${db_pass}" 2>/dev/null <<EOF
drop database if exists test;
delete from mysql.db where user='';
delete from mysql.db where user='PUBLIC';
delete from mysql.user where user='';
delete from mysql.user where user='mysql';
delete from mysql.user where user='PUBLIC';
flush privileges;
exit
EOF

if check_sys debian || check_sys ubuntu; then
    if [ -x "/etc/mysql/debian-start" ]; then
        # Add root password of MariaDB to file: /etc/mysql/debian.cnf
        cat >"/etc/mysql/debian.cnf" <<EOF
# THIS FILE IS OBSOLETE. STOP USING IT IF POSSIBLE.
# This file exists only for backwards compatibility for
# tools that run '--defaults-file=/etc/mysql/debian.cnf'
# and have root level access to the local filesystem.
# With those permissions one can run 'mariadb' directly
# anyway thanks to unix socket authentication and hence
# this file is useless. See package README for more info.
[client]
host     = localhost
user     = root
password = '${db_pass}'
[mysql_upgrade]
host     = localhost
user     = root
password = '${db_pass}'
# THIS FILE WILL BE REMOVED IN A FUTURE DEBIAN RELEASE.
EOF
        chmod 600 /etc/mysql/debian.cnf
    fi
fi

# Install phpMyAdmin
_error_detect "wget -qO pma.tar.gz https://dl.lamp.sh/files/pma.tar.gz"
_error_detect "tar zxf pma.tar.gz -C /data/www/default/"
_error_detect "rm -f pma.tar.gz"
_info "/usr/bin/mariadb -uroot -p 2>/dev/null < /data/www/default/pma/sql/create_tables.sql"
/usr/bin/mariadb -uroot -p"${db_pass}" 2>/dev/null </data/www/default/pma/sql/create_tables.sql
_info "MariaDB configuration completed"

if check_sys rhel; then
    php_conf="/etc/php-fpm.d/www.conf"
    php_ini="/etc/php.ini"
    php_fpm="php-fpm"
    php_sock="unix//run/php-fpm/www.sock"
    sock_location="/var/lib/mysql/mysql.sock"
    if get_rhelversion 8; then
        _error_detect "dnf install -yq https://rpms.remirepo.net/enterprise/remi-release-8.rpm"
    fi
    if get_rhelversion 9; then
        _error_detect "dnf install -yq https://rpms.remirepo.net/enterprise/remi-release-9.rpm"
    fi
    if get_rhelversion 10; then
        _error_detect "dnf install -yq https://rpms.remirepo.net/enterprise/remi-release-10.rpm"
    fi
    _error_detect "dnf module reset -yq php"
    _error_detect "dnf module install -yq php:remi-${php_ver}"
    _error_detect "dnf install -yq php-common php-fpm php-cli php-bcmath php-embedded php-gd php-imap php-mysqlnd php-dba php-pdo php-pdo-dblib"
    _error_detect "dnf install -yq php-pgsql php-odbc php-enchant php-gmp php-intl php-ldap php-snmp php-soap php-tidy php-opcache php-process"
    _error_detect "dnf install -yq php-pspell php-shmop php-sodium php-ffi php-brotli php-lz4 php-xz php-zstd php-pecl-rar php-pecl-swoole6"
    _error_detect "dnf install -yq php-pecl-imagick-im7 php-pecl-zip php-pecl-mongodb php-pecl-grpc php-pecl-yaml php-pecl-uuid composer"
elif check_sys debian || check_sys ubuntu; then
    php_conf="/etc/php/${php_ver}/fpm/pool.d/www.conf"
    php_ini="/etc/php/${php_ver}/fpm/php.ini"
    php_fpm="php${php_ver}-fpm"
    php_sock="unix//run/php/php-fpm.sock"
    sock_location="/run/mysqld/mysqld.sock"
    if check_sys debian; then
        _error_detect "curl -sSLo /usr/share/keyrings/deb.sury.org-php.gpg https://packages.sury.org/php/apt.gpg"
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/deb.sury.org-php.gpg] https://packages.sury.org/php/ $(lsb_release -sc) main" >/etc/apt/sources.list.d/php.list
    fi
    if check_sys ubuntu; then
        _error_detect "add-apt-repository -y ppa:ondrej/php"
    fi
    _error_detect "apt-get update"
    _error_detect "apt-get install -y php-common php${php_ver}-common php${php_ver}-cli php${php_ver}-fpm php${php_ver}-opcache php${php_ver}-readline"
    _error_detect "apt-get install -y libphp${php_ver}-embed php${php_ver}-bcmath php${php_ver}-gd php${php_ver}-imap php${php_ver}-mysql php${php_ver}-dba php${php_ver}-mongodb php${php_ver}-sybase"
    _error_detect "apt-get install -y php${php_ver}-pgsql php${php_ver}-odbc php${php_ver}-enchant php${php_ver}-gmp php${php_ver}-intl php${php_ver}-ldap php${php_ver}-snmp php${php_ver}-soap"
    _error_detect "apt-get install -y php${php_ver}-mbstring php${php_ver}-curl php${php_ver}-pspell php${php_ver}-xml php${php_ver}-zip php${php_ver}-bz2 php${php_ver}-lz4 php${php_ver}-zstd"
    _error_detect "apt-get install -y php${php_ver}-tidy php${php_ver}-sqlite3 php${php_ver}-imagick php${php_ver}-grpc php${php_ver}-yaml php${php_ver}-uuid php${php_ver}-swoole"
    _error_detect "mkdir -m770 /var/lib/php/{session,wsdlcache,opcache}"
fi
_info "PHP installation completed"

sed -i "s@^user.*@user = caddy@" "${php_conf}"
sed -i "s@^group.*@group = caddy@" "${php_conf}"
if check_sys rhel; then
    sed -i "s@^listen.acl_users.*@listen.acl_users = apache,nginx,caddy@" "${php_conf}"
    sed -i "s@^;php_value\[opcache.file_cache\].*@php_value\[opcache.file_cache\] = /var/lib/php/opcache@" "${php_conf}"
elif check_sys debian || check_sys ubuntu; then
    sed -i "s@^listen.owner.*@;&@" "${php_conf}"
    sed -i "s@^listen.group.*@;&@" "${php_conf}"
    sed -i "s@^;listen.acl_users.*@listen.acl_users = caddy@" "${php_conf}"
    sed -i "s@^;listen.allowed_clients.*@listen.allowed_clients = 127.0.0.1@" "${php_conf}"
    sed -i "s@^pm.max_children.*@pm.max_children = 50@" "${php_conf}"
    sed -i "s@^pm.start_servers.*@pm.start_servers = 5@" "${php_conf}"
    sed -i "s@^pm.min_spare_servers.*@pm.min_spare_servers = 5@" "${php_conf}"
    sed -i "s@^pm.max_spare_servers.*@pm.max_spare_servers = 35@" "${php_conf}"
    sed -i "s@^;slowlog.*@slowlog = /var/log/www-slow.log@" "${php_conf}"
    sed -i "s@^;php_admin_value\[error_log\].*@php_admin_value[error_log] = /var/log/www-error.log@" "${php_conf}"
    sed -i "s@^;php_admin_flag\[log_errors\].*@php_admin_flag[log_errors] = on@" "${php_conf}"
    cat >>"${php_conf}" <<EOF
php_value[session.save_handler] = files
php_value[session.save_path]    = /var/lib/php/session
php_value[soap.wsdl_cache_dir]  = /var/lib/php/wsdlcache
php_value[opcache.file_cache]   = /var/lib/php/opcache
EOF
fi
sed -i "s@^disable_functions.*@disable_functions = passthru,exec,shell_exec,system,chroot,chgrp,chown,proc_open,proc_get_status,ini_alter,ini_alter,ini_restore@" "${php_ini}"
sed -i "s@^max_execution_time.*@max_execution_time = 300@" "${php_ini}"
sed -i "s@^max_input_time.*@max_input_time = 300@" "${php_ini}"
sed -i "s@^post_max_size.*@post_max_size = 128M@" "${php_ini}"
sed -i "s@^upload_max_filesize.*@upload_max_filesize = 128M@" "${php_ini}"
sed -i "s@^expose_php.*@expose_php = Off@" "${php_ini}"
sed -i "s@^short_open_tag.*@short_open_tag = On@" "${php_ini}"
sed -i "s#mysqli.default_socket.*#mysqli.default_socket = ${sock_location}#" "${php_ini}"
sed -i "s#pdo_mysql.default_socket.*#pdo_mysql.default_socket = ${sock_location}#" "${php_ini}"
_error_detect "chown root:caddy /var/lib/php/{session,wsdlcache,opcache}"
_info "PHP configuration completed"

cat >"/etc/caddy/conf.d/default.conf" <<EOF
:80 {
	header {
		Strict-Transport-Security "max-age=31536000; preload"
		X-Content-Type-Options nosniff
		X-Frame-Options SAMEORIGIN
	}
	root * /data/www/default
	encode gzip
	php_fastcgi ${php_sock}
	file_server {
		index index.html
	}
	log {
		output file /var/log/caddy/access.log {
			roll_size 100mb
			roll_keep 3
			roll_keep_for 7d
		}
	}
}
EOF

_error_detect "cp -f ${cur_dir}/conf/lcmp /usr/bin/"
_error_detect "chmod 755 /usr/bin/lcmp"
_error_detect "chown -R caddy:caddy /data/www"
_error_detect "systemctl daemon-reload"
_error_detect "systemctl start ${php_fpm}"
_error_detect "systemctl start caddy"
sleep 3
_error_detect "systemctl restart ${php_fpm}"
_error_detect "systemctl restart caddy"
sleep 1
_info "systemctl enable mariadb"
systemctl enable mariadb >/dev/null 2>&1
_info "systemctl enable ${php_fpm}"
systemctl enable "${php_fpm}" >/dev/null 2>&1
_info "systemctl enable caddy"
systemctl enable caddy >/dev/null 2>&1
pkill -9 gpg-agent
_info "systemctl status mariadb"
systemctl --no-pager -l status mariadb
_info "systemctl status ${php_fpm}"
systemctl --no-pager -l status "${php_fpm}"
_info "systemctl status caddy"
systemctl --no-pager -l status caddy
echo
netstat -nxtulpe
echo
_info "LCMP (Linux + Caddy + MariaDB + PHP) installation completed"
