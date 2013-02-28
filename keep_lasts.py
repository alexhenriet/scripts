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
##
# EXAMPLE:
# ./keep_lasts.py --probe --number=2 /var/log/ mysql.log.*
# Keeping : /var/log/mysql.log.1.gz
# Keeping : /var/log/mysql.log.2.gz
# Removing : /var/log/mysql.log.3.gz
# Removing : /var/log/mysql.log.4.gz
# Removing : /var/log/mysql.log.5.gz

"""keep_lasts.py <dir> <mask> [--number=3] [--probe]"""

import os
import sys
import glob
import optparse


def main():
    """Main program."""
    parser = optparse.OptionParser(usage=__doc__, version="%prog 0.2")
    parser.add_option('', '--number', action='store', type='int',
                      dest='number', default=3,
                      help='Number of files to keep.')
    parser.add_option('', '--probe', action='store_true',
                      dest='probe', default=False,
                      help='Simulation preserving files.')
    (options, args) = parser.parse_args()
    if len(args) != 2:
        print bold("Usage: %s." % __doc__)
        sys.exit(1)
    directory, mask = args[0].rstrip('/'), args[1],
    number, probe = options.number, options.probe
    if not os.path.exists(directory):
        print red(bold('Error: a valid working directory must be provided'))
        sys.exit(1)
    files = glob.glob(directory + '/' + mask)
    if len(files) == 0:
        print bold('No matching files, terminating')
        sys.exit(0)
    files_by_date = []
    for _file in files:
        date_file_tuple = os.stat(_file)[8], _file
        files_by_date.append(date_file_tuple)
    files_by_date.sort()
    files_by_date.reverse()
    count = 0
    for _file in files_by_date:
        count += 1
        if count <= number:
            print bold('Keeping : ' + _file[1])
        else:
            print bold('Removing : ' + _file[1])
            if not probe:
                os.remove(_file[1])


def style(code, message):
    """Stylise message for output."""
    return '\x1b[%sm%s\x1b[0m' % (code, message)


def bold(message):
    """Stylise message in bold for output."""
    return style(1, message)


def red(message):
    """Stylise message in red for output."""
    return style(31, message)

if __name__ == '__main__':
    main()
