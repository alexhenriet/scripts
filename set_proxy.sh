#!/bin/bash
# Usage : "source set_proxy.sh"
echo -n "Proxy user: "
read login
echo -n "Proxy pass: "
read -s password
echo
export HTTP_PROXY="http://$login:$password@proxy:80"
export HTTPS_PROXY=$HTTP_PROXY
export FTP_PROXY=$HTTP_PROXY
export https_proxy=$HTTP_PROXY
export http_proxy=$HTTP_PROXY
export no_proxy=localhost
