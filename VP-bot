#!/usr/bin/env python
import os
import re
import sys

from twisted.internet import protocol, reactor
from twisted.protocols import basic
from twisted.python import log
from twisted.words.protocols import irc

class HissyIRCClient(irc.IRCClient):
	nickname = 'VP-Bot'
	channel = None

	def signedOn(self):
		log.msg("Connected to IRC server.")
		self.channel = self.factory.channel
		self.join(self.channel)

	def joined(self, channel):
		log.msg("Joined channel {0}.".format(channel))

	def privmsg(self, user, channel, msg):
		process = self.factory.process
		if process and user.find('!') != -1:
			nick = user[:user.find('!')]
			if channel != 'AUTH' and nick not in [self.nickname, 'Global']:
				cmd = ''.join([
						'say "', channel, ' <',
						escape(nick), '> ',
						escape(msg), '"'])
				log.msg(''.join(['IRC => ST: ', cmd]))
				process.transport.write(''.join([cmd, '\n']))

class HissyIRCClientFactory(protocol.ClientFactory):
	protocol = HissyIRCClient
	process = None
	connection = None

	def __init__(self, channel):
		self.channel = channel

	def buildProtocol(self, addr):
		log.msg("Connected to {0}".format(addr))
		self.connection = HissyIRCClient()
		self.connection.factory = self
		return self.connection

	def clientConnectionLost(self, connector, reason):
		log.msg("Lost connection: {0}".format((reason,)))
		connector.connect()

	def clientConnectionFailed(self, connector, reason):
		log.msg("Could not connect: {0}".format((reason,)))

def main(cmd = None):
	# Check to see if we actually have a valid command
	if not cmd:
		print("You need to run hissy with a command.")
		return 1

	log.startLogging(sys.stdout)

	hissyirc = HissyIRCClientFactory('#vp-surv')

	zandronum.irc = hissyirc

	# Connect to IRC
	reactor.connectTCP('irc.zandronum.com', 6667, hissyirc)

if __name__ == '__main__':
	main(sys.argv[1:])
