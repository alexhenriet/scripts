#!/bin/sh
# validated against https://www.shellcheck.net/
##
# Build optional libsodium via
# cd /tmp && wget https://download.libsodium.org/libsodium/releases/LATEST.tar.gz
# tar zxf LATEST.tar.gz && cd libsodium-stable
# ./configure && make && sudo make checkinstall (set correct version number)
# sudo dpkg -i sudo dpkg -i libsodium_(correct version number)_amd64.deb
# bash build_php_debian.sh --with-sodium

DEFAULT_PHP_VERSION="7.2.3"
BUILD_PATH="$HOME/httpd-build"
VAR_PATH="$HOME/var"
MYSQL_SOCK_PATH="/var/run/mysqld/mysqld.sock"

PARAMS=''
if ! [ -z "$1" ]; then
    PARAMS="$1"
fi

# Requirements check
DEBIAN_VERSION=$(sed 's/\..*//' /etc/debian_version)
if [ "$DEBIAN_VERSION" -eq "9" ]; then
REQUIRED_PACKAGES='tar bzip2 gcc g++ make sed dpkg-dev libfcgi-dev libfcgi0ldbl libjpeg62-turbo-dev libmcrypt-dev libssl-dev libc-client2007e-dev libxml2-dev libbz2-dev libcurl4-openssl-dev libjpeg-dev libpng-dev libfreetype6-dev libkrb5-dev libpq-dev libxml2-dev libxslt1-dev libicu-dev libpcre3-dev zlib1g-dev libldap2-dev libreadline-dev libldb-dev'
else
REQUIRED_PACKAGES='tar bzip2 gcc g++ make sed dpkg-dev libfcgi-dev libfcgi0ldbl libjpeg62-turbo-dbg libmcrypt-dev libssl-dev libc-client2007e-dev libxml2-dev libbz2-dev libcurl4-openssl-dev libjpeg-dev libpng12-dev libfreetype6-dev libkrb5-dev libpq-dev libxml2-dev libxslt1-dev libicu-dev libpcre3-dev zlib1g-dev libldap2-dev libreadline-dev libldb-dev'
fi
MISSING_PACKAGES=''
for PACKAGE in $REQUIRED_PACKAGES; do
  if ! dpkg -s "$PACKAGE" > /dev/null 2>&1; then
    MISSING_PACKAGES="$MISSING_PACKAGES $PACKAGE"
  fi
done
if [ "${#MISSING_PACKAGES}" -ne 0 ]; then
  printf "Error: missing packages %s\\n" "$MISSING_PACKAGES"
  exit 1
fi

# Script
if [ ! -d "$BUILD_PATH" ]; then
  mkdir "$BUILD_PATH" || exit 1
fi
cd "$BUILD_PATH" || exit 1
#SRC_FOLDERS=$(ls -d php-*/ 2>/dev/null|tr "\\n" ' ') # Replaced for shellcheck
SRC_FOLDERS="$(find . -maxdepth 1 -type d -name 'php-*' -printf '%P ')"
printf "PHP sources in BUILD_PATH (%s): %s\\n" "$BUILD_PATH" "$SRC_FOLDERS"
printf "PHP version to install (%s): " "$DEFAULT_PHP_VERSION"
read -r PHP_VERSION
if [ "${#PHP_VERSION}" -eq 0 ]; then
  PHP_VERSION="$DEFAULT_PHP_VERSION"
else
  if [ ! "${#PHP_VERSION}" = "$(expr "$PHP_VERSION" : "^[0-9]\\.[0-9]\\.[0-9]*$")" ]; then
    printf "Error: invalid PHP version\\n" && exit 1
  fi
fi

PHP_TARGET="$HOME/php-$PHP_VERSION"
if [ -e "$PHP_TARGET/bin/php" ]; then
  printf "Error: PHP version %s already installed at %s\\n" "$PHP_VERSION" "$PHP_TARGET" && exit 1
fi

PHP_URL="http://fr.php.net/distributions/php-$PHP_VERSION.tar.xz"
ARCHIVE="$(basename "$PHP_URL")"
if ! [ -e "$ARCHIVE" ]; then
  if ! wget --content-disposition "$PHP_URL"; then 
    printf "Error: unable to download PHP version %s\\n" "$PHP_VERSION" && exit 1
  fi
fi
FOLDER="$(basename "$ARCHIVE" .tar.xz)"
if [ ! -d "$FOLDER" ]; then
  if ! tar Jxf "$ARCHIVE"; then 
    printf "Error: unable to extract archive %s\\n" "$ARCHIVE" && exit 1
  fi
fi
cd "$FOLDER" || exit 1
printf "Building PHP %s\\n" "$PHP_VERSION"
export CFLAGS="-march=native -O3 -fomit-frame-pointer -pipe"
export CXXFLAGS="-march=native -O3 -fomit-frame-pointer -pipe"
ARCH="$(dpkg-architecture -q DEB_BUILD_GNU_TYPE)"
make clean
./configure --prefix="$PHP_TARGET" --sbindir="$PHP_TARGET/bin" --with-config-file-path="$PHP_TARGET/etc" --with-libdir="lib/$ARCH" --localstatedir="$VAR_PATH" --with-mysql-sock="$MYSQL_SOCK_PATH" --with-curl --disable-cgi --with-mysqli=mysqlnd --enable-pdo --with-pdo-mysql=mysqlnd --with-openssl --with-zlib --with-pcre-regex --with-sqlite3 --with-gd --with-ldap --with-curl --with-fpm-group="$USER" --with-fpm-user="$USER" --with-gettext --with-mhash --with-xmlrpc --with-bz2 --with-readline --enable-inline-optimization --enable-calendar --enable-bcmath --enable-exif --enable-mbregex --enable-sysvshm --enable-sysvsem --enable-sockets --enable-soap --enable-sockets --enable-ftp --enable-bcmath --enable-intl --enable-mbstring --enable-zip --enable-fpm --enable-opcache $PARAMS
make -j4 || exit 1 
make install || exit 1

if ! [ -e "$PHP_TARGET/etc/php.ini" ]; then
  cp 'php.ini-production' "$PHP_TARGET/etc/php.ini"
  sed -i "s,;opcache.enable=1,opcache.enable=1," "$PHP_TARGET/etc/php.ini"
  sed -i "s,;opcache.max_accelerated_files=10000,opcache.max_accelerated_files=20000," "$PHP_TARGET/etc/php.ini"
  sed -i "s,;realpath_cache_size = 4096k,realpath_cache_size = 4096k," "$PHP_TARGET/etc/php.ini"
  sed -i "s,;realpath_cache_ttl = 120,realpath_cache_ttl = 600," "$PHP_TARGET/etc/php.ini"
  printf 'zend_extension=opcache.so' >> "$PHP_TARGET/etc/php.ini"
fi

if ! [ -e "$PHP_TARGET/etc/php-fpm.conf" ]; then
  if [ -e "$PHP_TARGET/etc/php-fpm.conf.default" ]; then
    cp "$PHP_TARGET/etc/php-fpm.conf.default" "$PHP_TARGET/etc/php-fpm.conf"
    sed -i "s,listen = 127.0.0.1:9000,listen = $VAR_PATH/php-fpm-$PHP_VERSION.sock,g" "$PHP_TARGET/etc/php-fpm.conf"
    sed -i "s,\\[www\\],[www-$PHP_VERSION]," "$PHP_TARGET/etc/php-fpm.conf"
  fi
fi

if ! [ -e "$PHP_TARGET/etc/php-fpm.d/www.conf" ]; then
  if [ -e "$PHP_TARGET/etc/php-fpm.d/www.conf.default" ]; then
    cp "$PHP_TARGET/etc/php-fpm.d/www.conf.default" "$PHP_TARGET/etc/php-fpm.d/www.conf"
    sed -i "s,listen = 127.0.0.1:9000,listen = $VAR_PATH/php-fpm-$PHP_VERSION.sock,g" "$PHP_TARGET/etc/php-fpm.d/www.conf"
    sed -i "s,\\[www\\],[www-$PHP_VERSION]," "$PHP_TARGET/etc/php-fpm.d/www.conf"
  fi
fi
