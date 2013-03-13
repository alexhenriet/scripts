#!/home/alex/python-2.2.3/bin/python
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
# About :
# - Simple IRC BOT
# - Compatible with naked python 2.2.3
##
# Missing:
# - Daemonize
# - Authentication
# - Raw command
# - Switch ident in case of ban

"""Dumb IRC Bot."""

import socket
import sys
import time
import re
import random


class Dumbot:
    """The bot."""

    def __init__(self, nickname='Dumbot', ident='dumbot', realname='Dumbot v0.1',
                 host='irc.freenode.net', port=6667, chan='#loligrub',
                 botlog='bot.log', chanlog='loligrub.log', verbose=True):
        """Constructor."""
        self.sock = None
        self.nickname = nickname
        self.firstnick = nickname
        self.ident = ident
        self.realname = realname
        self.host = host
        self.port = port
        self.chan = chan
        self.alive = True
        self.online = False
        self.attempts = 1
        self.max_attempts = 20
        self.attempts_sleep = 10
        self.botlog = open(botlog, 'a')
        self.chanlog = open(chanlog, 'a')
        self.verbose = verbose

    def _log(self, log, message):
        """Log message to open file."""
        log_entry = '[%s] %s\n' % (time.strftime('%Y/%m/%d %H:%M:%S'), message)
        log.write(log_entry)
        if self.verbose:
            print log_entry.rstrip()

    def _connect(self):
        """Connect to server."""
        try:
            self._log(self.botlog, 'Attempt to connect to %s:%s' % (self.host, self.port))
            self.sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            self.sock.connect((self.host, self.port))
            self._log(self.botlog, 'Connected to %s:%s' % (self.host, self.port))
            self.attempts = 0
            self.online = True
        except socket.error:
            self._log(self.botlog, 'Unable to connect (Attempt %d on %d)' % (
                self.attempts, self.max_attempts))
            self.sock.close()
            self.sock = None
            if self.attempts == self.max_attempts:
                self.alive = False
            self.attempts += 1
            return

    def _send(self, message):
        """Send message to server."""
        self.sock.sendall('%s\n' % message)

    def _register(self):
        """Register user on server."""
        self._log(self.botlog, 'Registering as %s' % self.nickname)
        self._send('USER %s B C :%s' % (self.ident, self.realname))
        self._send('NICK %s' % self.nickname)

    def _switch_nick(self):
        """Switch to alternate nickname."""
        self.nickname = self.firstnick + str(random.randint(1000, 9999))
        self._log(self.botlog, 'Switching to nick %s' % self.nickname)
        self._send('NICK %s' % self.nickname)

    def _join(self):
        """Join channel."""
        self._send('JOIN %s' % self.chan)

    def _hook_on_ping_and_motd(self):
        """Hook for repetitive tasks."""
        self._join()

    def _hook_on_privmsg(self, nickname, ident, hostname, target, message):
        """Treat PRIVMSGs."""
        log_entry = '<%s!%s@%s> %s' % (nickname, ident, hostname, message)
        if target == self.chan:
            self._log(self.chanlog, log_entry)
        elif target == self.nickname:
            self._log(self.botlog, log_entry)

    def _hook_on_kick(self, nickname, ident, hostname, channel, target, message):
        """Treat KICKs."""
        if target == self.nickname:
            self._log(self.botlog, 'Kicked from %s by <%s!%s@%s> with reason : %s' % (
                channel, nickname, ident, hostname, message))
            self._switch_nick()
            self._join()

    def _hook_on_join(self, nickname, ident, hostname, channel):
        """Treat JOINs."""
        pass

    def _on_data(self, data):
        """Treat incomming data."""
        # Handling PING => PING :server.hostname
        if data.startswith('PING'):
            self._send('PONG :%s' % data.split(':')[1])
            self._hook_on_ping_and_motd()
            return
        elif data.find('PRIVMSG') != -1:
            # Handling PRIVMSG => :_Setsuna_!~alex@127.0.0.1 PRIVMSG #dev :bla bla
            match = re.compile(r':([^!]+)!([^@]+)@([^\s]+) PRIVMSG ([^\s]+) :(.*)').match(data)
            if match:
                val = match.groups()
                self._hook_on_privmsg(val[0], val[1], val[2], val[3], val[4])
                return
        elif data.find('JOIN') != -1:
            # Handling JOIN => :_Setsuna_!~alex@127.0.0.1 JOIN :#dev
            match = re.compile(r':([^!]+)!([^@]+)@([^\s]+) JOIN :(.*)').match(data)
            if match:
                val = match.groups()
                self._hook_on_join(val[0], val[1], val[2], val[3])
                return
        elif data.find('KICK') != -1:
            # Handling KICK => :Dumbot!~alex@127.0.0.1 KICK #dev Dumbot3089 :no reason
            match = re.compile(r':([^!]+)!([^@]+)@([^\s]+) KICK ([^\s]+) ([^\s]+) :(.*)').match(data)
            if match:
                val = match.groups()
                self._hook_on_kick(val[0], val[1], val[2], val[3], val[4], val[5])
                return
        elif data.find('433') != -1:
            # Handling NICK ALREADY IN USE => :irc.localhost 433 * Dumbot4567 :Nick...
            if re.compile(r':[^\s]+ 433.*').match(data):
                self._switch_nick()
                return
        elif data.find('376') != -1:
            # Handling :irc.localhost 376 Dumbot45674836 :End of MOTD command
            if re.compile(r':[^\s]+ 376.*').search(data):
                self._hook_on_ping_and_motd()
                return

    def _socket_loop(self):
        """Loop while connected."""
        while(self.online):
            data = self.sock.recv(2048).strip()
            if data:
                self._on_data(data)
            else:
                self.online = False
        self._log(self.botlog, 'Disconnected from %s:%s' % (self.host, self.port))

    def run_baby_run(self):
        """Bot loop."""
        while self.alive:
            self._connect()
            if self.sock:
                self._register()
                self._socket_loop()
            self._log(self.botlog, 'Sleeping for %d seconds before retrying to connect %s:%s' % (
                self.attempts_sleep, self.host, self.port))
            time.sleep(self.attempts_sleep)
        self.botlog.close()
        self.chanlog.close()


def main():
    """Main function."""
    try:
        dumbot = Dumbot(host='localhost', chan='#dev')
        dumbot.run_baby_run()
    except KeyboardInterrupt:
        print "Shutting down."
        sys.exit(0)
    except Exception, err:
        print "Error: %s" % err
        sys.exit(1)

if __name__ == '__main__':
    main()
