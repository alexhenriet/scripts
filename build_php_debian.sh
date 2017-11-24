#!/bin/sh
# validated against https://www.shellcheck.net/
set -o posix

BUILD_PATH="$HOME/httpd-build"
VAR_PATH="$HOME/var"

# Requirements check
REQUIRED_PACKAGES='tar bzip2 gcc g++ make sed libfcgi-dev libfcgi0ldbl libjpeg62-turbo-dbg libmcrypt-dev libssl-dev libc-client2007e-dev libxml2-dev libbz2-dev libcurl4-openssl-dev libjpeg-dev libpng12-dev libfreetype6-dev libkrb5-dev libpq-dev libxml2-dev libxslt1-dev libicu-dev libpcre3-dev zlib1g-dev libldap2-dev libreadline-dev libldb-dev'
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
printf "PHP Version? (i.e.: 7.1.12)\\n"
read -r PHP_VERSION
if [ ! "${#PHP_VERSION}" = "$(expr "$PHP_VERSION" : "^[0-9]\\.[0-9]\\.[0-9]*$")" ]; then
  printf "Error: invalid PHP version\\n" && exit 1
fi

PHP_TARGET="$HOME/php-$PHP_VERSION"
#if [ -d "$PHP_TARGET" ]; then
#  printf "Error: PHP version %s already installed\\n" "$PHP_TARGET" || exit 1
#fi

PHP_URL="http://be2.php.net/distributions/php-$PHP_VERSION.tar.bz2"
if [ ! -d "$BUILD_PATH" ]; then
  mkdir "$BUILD_PATH" || exit 1
fi
cd "$BUILD_PATH" || exit 1
ARCHIVE="$(basename "$PHP_URL")"
if ! [ -e "$ARCHIVE" ]; then
  if ! wget --content-disposition "$PHP_URL"; then 
    printf "Error: unable to download PHP version %s\\n" "$PHP_VERSION" && exit 1
  fi
fi
FOLDER="$(basename "$ARCHIVE" .tar.bz2)"
if [ ! -d "$FOLDER" ]; then
  if ! tar jxf "$ARCHIVE"; then 
    printf "Error: unable to extract archive %s\\n" "$ARCHIVE" && exit 1
  fi
fi
cd "$FOLDER" || exit 1
printf "Building PHP %s\\n" "$PHP_VERSION"
export CFLAGS="-march=native -O2 -fomit-frame-pointer -pipe"
export CXXFLAGS="-march=native -O2 -fomit-frame-pointer -pipe"
ARCH="$(dpkg-architecture -q DEB_BUILD_GNU_TYPE)"
#make clean
#./configure --prefix="$PHP_TARGET" --with-libdir="lib/$ARCH" --localstatedir="$VAR_PATH" --disable-cgi --with-mysqli=mysqlnd --enable-pdo --with-pdo-mysql=mysqlnd --with-openssl --with-zlib --with-pcre-regex --with-sqlite3 --with-gd --with-ldap --with-curl --with-fpm-group="$USER" --with-fpm-user="$USER" --with-gettext --with-mhash --with-xmlrpc --with-bz2 --with-readline --enable-inline-optimization --enable-calendar --enable-bcmath --enable-exif --enable-mbregex --enable-sysvshm --enable-sysvsem --enable-sockets --enable-soap --enable-sockets --enable-ftp --enable-bcmath --enable-intl --enable-mbstring --enable-zip --enable-fpm --enable-opcache
#make || exit 1 
#make install || exit 1
cd "$BUILD_PATH" || exit 1

if ! [ -e "$PHP_TARGET/etc/php-fpm.conf" ]; then
  if [ -e "$PHP_TARGET/etc/php-fpm.conf.default" ]; then
    cp "$PHP_TARGET/etc/php-fpm.conf.default" "$PHP_TARGET/etc/php-fpm.conf"
    sed -i "s,\\[www\\],[www-$PHP_VERSION]," "$PHP_TARGET/etc/php-fpm.conf"
  fi
fi

if ! [ -e "$PHP_TARGET/etc/php-fpm.d/www.conf" ]; then
  if [ -e "$PHP_TARGET/etc/php-fpm.d/www.conf.default" ]; then
    cp "$PHP_TARGET/etc/php-fpm.d/www.conf.default" "$PHP_TARGET/etc/php-fpm.d/www.conf"
    sed -i "s,listen = 127.0.0.1:9000,listen = $PHP_TARGET/php-fpm-$PHP_VERSION.sock,g" "$PHP_TARGET/etc/php-fpm.d/www.conf"
    sed -i "s,\\[www\\],[www-$PHP_VERSION]," "$PHP_TARGET/etc/php-fpm.d/www.conf"
  fi
fi


#
