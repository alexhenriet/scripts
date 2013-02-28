#!/usr/bin/env python
# -*- coding: utf-8 -*-
##
# MIT Licence Copyright (c) 2013 Alexandre Henriet <alex.henriet@gmail.com>
#
# Permission is hereby granted, free of charge, to any person obtaining a
# copy of this software and associated documentation files (the "Software"),
# to deal in the Software without restriction, including without limitation
# the rights to use, copy, modify, merge, publish, distribute, sublicense,
# and/or sell copies of the Software, and to permit persons to whom the
# Software is furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included
# in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
# THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR
# OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
# ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
# OTHER DEALINGS IN THE SOFTWARE.

"""http_serve.py <docroot> [--ip=<ip>] [--port=<port>]"""

import sys
import os
import SimpleHTTPServer
import SocketServer
import socket
import optparse
import subprocess
import shlex
import re


def main():
    """Main program."""
    parser = optparse.OptionParser(usage=__doc__, version="%prog 0.3")
    parser.add_option("", "--ip", dest="ip_addr",
                      default="0.0.0.0", help="IP address to bind to.")
    parser.add_option("", "--port", dest="port", type="int",
                      default="41982", help="TCP port to bind to.")
    (options, args) = parser.parse_args()
    if len(args) != 1:
        print bold("Usage: %s." % __doc__)
        sys.exit(1)
    docroot, ip_addr, port = (args[0], options.ip_addr, options.port)
    if not os.access(docroot, os.R_OK):
        print red(bold("Error: folder %s is not readable." % docroot))
        sys.exit(1)
    try:
        urls = []
        if ip_addr == '0.0.0.0':
            for host_ip in host_ips():
                urls.append('http://%s:%s' % (host_ip, port))
        else:
            urls.append('http://%s:%s' % (ip_addr, port))
        print bold("Serving %s on %s" % (docroot, ', '.join(urls)))
        os.chdir(docroot)
        handler = SimpleHTTPServer.SimpleHTTPRequestHandler
        SocketServer.TCPServer.allow_reuse_address = True
        httpd = SocketServer.TCPServer((ip_addr, port), handler)
        httpd.serve_forever()
    except socket.error:
        print red(bold("Error: unable to bind %s:%s." % (ip_addr, port)))
        sys.exit(1)
    except KeyboardInterrupt:
        httpd.server_close()
        print bold("\nShutting down, goodbye.")
        sys.exit(0)


def host_ips():
    """Return host IP addresses."""
    cmd_args = shlex.split('/sbin/ifconfig -a')
    proc = subprocess.Popen(cmd_args, stdout=subprocess.PIPE)
    return re.findall('inet adr:(.+?) ', proc.stdout.read())


def style(code, message):
    """Stylise message for output."""
    return '\x1b[%sm%s\x1b[0m' % (code, message)


def bold(message):
    """Stylise message in bold for output."""
    return style(1, message)


def red(message):
    """Stylise message in red for output."""
    return style(31, message)

if __name__ == "__main__":
    main()
