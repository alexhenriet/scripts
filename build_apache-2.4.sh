#!/bin/bash

export CFLAGS="-march=native -O2 -fomit-frame-pointer -pipe" && export CXXFLAGS="-march=native -O2 -fomit-frame-pointer -pipe"

# SCRIPTPATH="$( cd "$(dirname "$0")" ; pwd -P )"
BUILDPATH=$HOME/httpd-build
APACHE_TARGET=$HOME/httpd
VAR_TARGET=$HOME/var
LIBS_TARGET=$HOME/httpd-libs

APACHE_URL="http://apache.cu.be//httpd/httpd-2.4.29.tar.bz2"
APR_URL="http://apache.cu.be//apr/apr-1.6.3.tar.bz2"
APR_UTIL_URL="http://apache.cu.be//apr/apr-util-1.6.1.tar.bz2"
OPENSSL_URL="https://www.openssl.org/source/openssl-1.1.0g.tar.gz"
PCRE_URL="https://ftp.pcre.org/pub/pcre/pcre-8.41.tar.gz"
EXPAT_URL="http://download.openpkg.org/components/cache/expat/expat-2.2.5.tar.bz2"
ZLIB_URL="http://zlib.net/zlib-1.2.11.tar.gz"

ARCHIVES=($APACHE_URL $APR_URL $APR_UTIL_URL $OPENSSL_URL $PCRE_URL $EXPAT_URL $ZLIB_URL)

if [ ! -d "$BUILDPATH" ]; then
  mkdir $BUILDPATH
fi
cd $BUILDPATH

for ARCHIVE_URL in ${ARCHIVES[@]}; do
  ARCHIVE_FILE=`basename $ARCHIVE_URL`
  if ! [ -e $ARCHIVE_FILE ]; then
    echo "Downloading missing archive $ARCHIVE_FILE"
    wget $ARCHIVE_URL
  fi
done

if ! [ -e "$LIBS_TARGET/bin/openssl" ]; then
  echo "Building OpenSSL"
  ARCHIVE=`basename $OPENSSL_URL`
  FOLDER=`basename $ARCHIVE .tar.gz`
  tar zxf $ARCHIVE
  cd $FOLDER
  ./config --prefix=$LIBS_TARGET
  make && make install
  cd ..
fi

if ! [ -e "$LIBS_TARGET/include/expat.h" ]; then
  echo "Building Expat"
  ARCHIVE=`basename $EXPAT_URL`
  FOLDER=`basename $ARCHIVE .tar.bz2`
  tar jxf $ARCHIVE
  cd $FOLDER
  ./configure --prefix=$LIBS_TARGET
  make && make install
  cd ..
fi


if ! [ -e "$LIBS_TARGET/bin/apr-1-config" ]; then
  echo "Building Apr"
  ARCHIVE=`basename $APR_URL`
  FOLDER=`basename $ARCHIVE .tar.bz2`
  tar jxf $ARCHIVE
  cd $FOLDER
  ./configure --prefix=$LIBS_TARGET
  make && make install
  cd ..
fi

if ! [ -e "$LIBS_TARGET/bin/apu-1-config" ]; then
  echo "Building Apr util"
  ARCHIVE=`basename $APR_UTIL_URL`
  FOLDER=`basename $ARCHIVE .tar.bz2`
  tar jxf $ARCHIVE
  cd $FOLDER
  ./configure --prefix=$LIBS_TARGET --with-apr=$LIBS_TARGET --with-expat=$LIBS_TARGET
  make && make install
  cd ..
fi

if ! [ -e "$LIBS_TARGET/bin/pcre-config" ]; then
  echo "Building Pcre"
  ARCHIVE=`basename $PCRE_URL`
  FOLDER=`basename $ARCHIVE .tar.gz`
  tar zxf $ARCHIVE
  cd $FOLDER
  ./configure --prefix=$LIBS_TARGET --disable-cpp
  make && make install
  cd ..
fi

if ! [ -e "$LIBS_TARGET/lib/libz.so" ]; then
  echo "Building Zlib"
  ARCHIVE=`basename $ZLIB_URL`
  FOLDER=`basename $ARCHIVE .tar.gz`
  tar zxf $ARCHIVE
  cd $FOLDER
  ./configure --prefix=$LIBS_TARGET
  make && make install
  cd ..
fi

if ! [ -e "$APACHE_TARGET/bin/httpd" ]; then
  echo "Building Httpd"
  ARCHIVE=`basename $APACHE_URL`
  FOLDER=`basename $ARCHIVE .tar.bz2`
  tar jxf $ARCHIVE
  cd $FOLDER
  ./configure --prefix=$APACHE_TARGET --localstatedir=$VAR_TARGET --with-apr=$LIBS_TARGET --with-apr-util=$LIBS_TARGET --with-pcre=$LIBS_TARGET --with-ssl=$LIBS_TARGET --with-z=$LIBS_TARGET --with-port=8000 --enable-ssl --enable-rewrite --enable-so --enable-shared --enable-mime-magic --enable-expires --enable-deflate --enable-mpms-shared
  make && make install
  cd ..
fi
