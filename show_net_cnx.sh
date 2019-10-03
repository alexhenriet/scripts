#!/usr/bin/env sh
ss -rp -4 state connected | grep -v localhost
