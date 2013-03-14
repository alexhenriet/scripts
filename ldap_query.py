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

"""./ldap_query.py filter_value [--filter=sAMAccountName] [--all]"""

import sys
import optparse
import ldap

LDAP_URL = 'ldap://ldap_server_host:ldap_server_port'
LDAP_LOGIN = r'bind_login'
LDAP_PASSWORD = 'bind_password'
LDAP_BASE_DN = 'OU=...,DC=company,DC=be'
LDAP_LOGIN_ATTR = 'sAMAccountName'


def main():
    """Main function."""
    parser = optparse.OptionParser(usage=__doc__, version='%prog 0.1')
    parser.add_option("-f", '--filter', dest='filter',
                      default=LDAP_LOGIN_ATTR, help='Search filter')
    parser.add_option("-a", '--all', dest='retrieve_all', action="store_true",
                      default=False, help='Retrieve all attributes')
    (options, args) = parser.parse_args()
    if len(args) != 1:
        print 'Usage: %s.' % __doc__
        sys.exit(1)
    search_filter_value = args[0]
    try:
        con = ldap.initialize(LDAP_URL)
        con.protocol_version = ldap.VERSION3
        con.simple_bind_s(LDAP_LOGIN, LDAP_PASSWORD)
        if options.retrieve_all:
            attributes = None  # All available attributes will be returned
        else:
            attributes = [
                'sAMAccountName',
                'displayName',
                '...',
            ]
        formated_filter = '%s=*%s*' % (options.filter, search_filter_value)
        results = con.search_s(LDAP_BASE_DN,
                               ldap.SCOPE_SUBTREE,
                               formated_filter,
                               attributes)
        if len(results) == 0:
            print 'No match'
            sys.exit(0)
        for entry_dn, entry in results:
            print '\n%s\n' % entry_dn
            line_format = '%31s: %s'
            if attributes:  # Use list order if list exists ..
                for attribute in attributes:
                    if attribute in entry:
                        print line_format % (attribute, entry[attribute][0])
            else:  # Display all attributes in default order
                for attribute, value in entry.items():
                    print line_format % (attribute, value[0])
        print
    except ldap.LDAPError, error:
        print 'Error: %s' % error
        sys.exit(1)

if __name__ == '__main__':
    main()
