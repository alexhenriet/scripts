#!/bin/sh
# validated against https://www.shellcheck.net/

BUILD_PATH="$HOME/httpd-build"
VAR_PATH="$HOME/var"

# Requirements check
REQUIRED_PACKAGES='tar bzip2 gcc g++ make sed libfcgi-dev libfcgi0ldbl libssl-dev libpcre3-dev zlib1g-dev libapr1-dev libaprutil1-dev'
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
HTTPD_VERSION="2.4.29"

HTTPD_TARGET="$HOME/httpd-$HTTPD_VERSION"
if [ -e "$HTTPD_TARGET/bin/httpd" ]; then
  printf "Error: HTTPD version %s already installed at %s\\n" "$HTTPD_VERSION" "$HTTPD_TARGET" && exit 1
fi

HTTPD_URL="http://apache.cu.be//httpd/httpd-$HTTPD_VERSION.tar.bz2"
if [ ! -d "$BUILD_PATH" ]; then
  mkdir "$BUILD_PATH" || exit 1
fi
cd "$BUILD_PATH" || exit 1
ARCHIVE="$(basename "$HTTPD_URL")"
if ! [ -e "$ARCHIVE" ]; then
  if ! wget --content-disposition "$HTTPD_URL"; then 
    printf "Error: unable to download HTTPD version %s\\n" "$HTTPD_VERSION" && exit 1
  fi
fi
FOLDER="$(basename "$ARCHIVE" .tar.bz2)"
if [ ! -d "$FOLDER" ]; then
  if ! tar jxf "$ARCHIVE"; then 
    printf "Error: unable to extract archive %s\\n" "$ARCHIVE" && exit 1
  fi
fi
cd "$FOLDER" || exit 1
printf "Building HTTPD %s\\n" "$HTTPD_VERSION"
export CFLAGS="-march=native -O2 -fomit-frame-pointer -pipe"
export CXXFLAGS="-march=native -O2 -fomit-frame-pointer -pipe"
ARCH="$(dpkg-architecture -q DEB_BUILD_GNU_TYPE)"
./configure --prefix=$HTTPD_TARGET --localstatedir=$VAR_PATH --with-port=8000 --enable-ssl --enable-rewrite --enable-so --enable-shared --enable-mime-magic --enable-expires --enable-deflate --enable-mpms-shared
make || exit 1
make install || exit 1
cd "$BUILD_PATH" || exit 1

if [ -e "$HTTPD_TARGET/conf/httpd.conf" ]; then
    sed -i "s,^Listen 8000,#Listen 8000," "$HTTPD_TARGET/conf/httpd.conf"
    sed -i "s,#Include conf/extra/httpd-vhosts.conf,Include conf/extra/httpd-vhosts.conf," "$HTTPD_TARGET/conf/httpd.conf"
    sed -i "s,#LoadModule proxy_module modules/mod_proxy.so,LoadModule proxy_module modules/mod_proxy.so," "$HTTPD_TARGET/conf/httpd.conf"
    sed -i "s,#LoadModule proxy_fcgi_module modules/mod_proxy_fcgi.so,LoadModule proxy_fcgi_module modules/mod_proxy_fcgi.so," "$HTTPD_TARGET/conf/httpd.conf"
    sed -i "s,#LoadModule rewrite_module modules/mod_rewrite.so,LoadModule rewrite_module modules/mod_rewrite.so," "$HTTPD_TARGET/conf/httpd.conf"
    sed -i "s,#LoadModule deflate_module modules/mod_deflate.so,LoadModule deflate_module modules/mod_deflate.so," "$HTTPD_TARGET/conf/httpd.conf"
    sed -i "s,DirectoryIndex index.html,DirectoryIndex index.php index.html," "$HTTPD_TARGET/conf/httpd.conf"
fi

if [ ! -e "$HOME/www/dummy/web/index.php" ]; then
  if [ ! -d "$HOME/www/dummy/web" ]; then
    mkdir -p "$HOME/www/dummy/web"
  fi
  printf "<?php\nphpinfo();" > "$HOME/www/dummy/web/index.php"
fi

if [ -e "$HTTPD_TARGET/conf/extra/httpd-vhosts.conf" ]; then
  TIMESTAMP="$(date +%s)"
  cp "$HTTPD_TARGET/conf/extra/httpd-vhosts.conf" "$HTTPD_TARGET/conf/extra/httpd-vhosts.conf.$TIMESTAMP"
  cat > "$HTTPD_TARGET/conf/extra/httpd-vhosts.conf" << EOF
Listen 8000
<VirtualHost *:8000>
    DocumentRoot "$HOME/www/dummy/web/"
    ProxyPassMatch ^/(.*\.php(/.*)?)$ unix://$HOME/var/php-fpm-7.1.12.sock|fcgi://127.0.0.1:9000$HOME/www/dummy/web/
    #ProxyPassMatch ^/(.*\.php(/.*)?)$ unix://$HOME/var/php-fpm-5.6.31.sock|fcgi://127.0.0.1:9000$HOME/www/dummy/web/
    #ProxyPassMatch ^/(.*\.php(/.*)?)$ unix://$HOME/var/php-fpm-5.4.45.sock|fcgi://127.0.0.1:9000$HOME/www/dummy/web/
    <Directory $HOME/www/dummy/web/>
      Options Indexes FollowSymLinks MultiViews
      AllowOverride all 
      Require all granted
    </Directory>
    ErrorLog "$HOME/var/logs/dummy-error_log"
    CustomLog "$HOME/var/logs/dummy-access_log" common
</VirtualHost>
EOF
fi
