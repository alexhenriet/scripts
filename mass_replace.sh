#!/bin/sh
# validated against https://www.shellcheck.net/
# ./mass_replace.sh from to root
##

if [ -z "$1" ] || [ -z "$2" ]; then
  printf "Error: syntax ./mass_replace.sh FROM_STR TO_STR\\n"
  exit 1
fi
grep -iRl "$1"| xargs -i@ sed -i "s/$1/$2/g" @
