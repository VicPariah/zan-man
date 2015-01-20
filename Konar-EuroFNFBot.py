#!/usr/bin/env python
import os
import re
import sys

import time
import datetime

from twisted.internet import protocol, reactor, defer
from twisted.protocols import basic
from twisted.python import log
from twisted.words.protocols import irc


class zandronumProcessProtocol(protocol.ProcessProtocol):
	lre = {}
	irc = None

	def __init__(self):
		line_regex = {
			'addr': r'^IP address (.*)$',
			'chat': r'^CHAT (.*)$',
			'connect': r'^(.*) ' + '\x1c' + r'-has connected\.$',
			'disconnect': r'^client (.*) ' + '\x1c' + r'-disconnected.$',
			'level': r'^\*{3} (.*): (.*) \*{3}$',
			'win': r'^(.*) ' + '\x1c' + r'-wins!$',
			}

		for k, v in line_regex.items():
			self.lre[k] = re.compile(v)

	def connectionMade(self):
		log.msg('zandronum server starting up.')

	def processExited(self, reason):
		log.msg('zandronum server exited. Reason: {0}'.format(reason))

	def processEnded(self, reason):
		log.msg('zandronum server ended. Reason: {0}'.format(reason))
	
	def errReceived(self, data):
		for line in data.splitlines():
			log.msg(line)

	def outReceived(self, data):
		# Line-by-line parsing
		for line in data.splitlines():
			# Client talked
			chat = self.lre['chat'].search(line)
			if chat:
				msg = chat.group(1)

				if self.irc.connection:
					if msg[:8] != '<server>':
						log.msg(''.join(['ST => IRC: ', msg]))
						self.irc.connection.say(
							self.irc.connection.channel, irccolorize(msg))
				else:
					log.msg("Can't send message, not connected to IRC.")

			# Client connected
			connect = self.lre['connect'].search(line)
			if connect:
				client = connect.group(1)
				log.msg('Client {0} connected.'.format(client))

				try:
					self.irc.connection.say(
						self.irc.connection.channel,
						'{0}\x0f connected.'.format(irccolorize(client)))
				except TypeError:
					log.msg("Can't send message, not connected to IRC.")

			# Client disconnected
			disconnect = self.lre['disconnect'].search(line)
			if disconnect:
				client = disconnect.group(1)
				log.msg('Client {0} disconnected.'.format(client))

				if self.irc.connection:
					self.irc.connection.say(
						self.irc.connection.channel,
						'{0}\x0f disconnected.'.format(irccolorize(client)))

			# Server changed level
			level = self.lre['level'].search(line)
			if level:
				lump, name = level.groups()
				log.msg('Server changed level to {0}: {1}.'.format(lump, name))

				try:
					self.irc.connection.say(
						self.irc.connection.channel,
						'Changed level to {0}: {1}.'.format(lump, name))
				except TypeError:
					log.msg("Can't send message, not connected to IRC.")

			# Client won
			win = self.lre['win'].search(line)
			if win:
				client = win.group(1)
				log.msg('{0} wins!'.format(client))

				try:
					self.irc.connection.say(
						self.irc.connection.channel,
						'{0}\x0f wins!'.format(irccolorize(client)))
				except TypeError:
					log.msg("Can't send message, not connected to IRC.")

			# IP address was revealed
			addr = self.lre['addr'].search(line)
			if addr:
				log.msg('Server listening on {0}.'.format(addr.group(0)))










class HissyIRCClient(irc.IRCClient):
	nickname = 'EUFNF-Bot'
	channel = None


	def got_names(self, nicklist):
		#log.msg(nicklist)
		nicklist = ' '.join(nicklist)
		nicklist = re.sub('[@%+]', '', nicklist)
		self.sendLine("PRIVMSG %s :%s" % (self.channel, nicklist))
		self.sendLine("PRIVMSG %s :%s" % (self.channel, "Come play [UK] -->Grandvoid--> EURO FRIDAY NIGHT FRAGFEST #214 - Legendary CTF ( 109.74.206.218:17009 )"))

	def signedOn(self):
		log.msg("Connected to IRC server.")
		self.channel = self.factory.channel
		self.join(self.channel)
		self.mode(self.nickname, True, '+BDLT-w', limit=None, user=self.nickname)

	def joined(self, channel):
		log.msg("Joined channel {0}.".format(channel))
		if datetime.date.today().strftime("%w") == '5' and datetime.datetime.now().strftime("%H-%M") == '17-59':
			time.sleep(30)
			self.names(channel).addCallback(self.got_names)

	def privmsg(self, user, channel, msg):
		process = self.factory.process
		if process and user.find('!') != -1:
			nick = user[:user.find('!')]
			if channel != 'AUTH' and nick not in [self.nickname, 'Global']:
				if msg[:6] == '.rcon ':
					cmd = re.sub('^\.rcon ', '', msg)
					log.msg(''.join(['IRC => RCON: ', cmd]))
					process.transport.write(''.join([cmd, '\n']))
					return
				cmd = ''.join([
						'say_bot "<', escape(nick), ' @ ', channel, '>: ', escape(msg), '"'])
				log.msg(''.join(['IRC => ST: ', cmd]))
				process.transport.write(''.join([cmd, '\n']))





#class NamesIRCClient(irc.IRCClient):
	def __init__(self, *args, **kwargs):
		self._namescallback = {}

	def names(self, channel):
		channel = channel.lower()
		d = defer.Deferred()
		if channel not in self._namescallback:
			self._namescallback[channel] = ([], [])

		self._namescallback[channel][0].append(d)
		self.sendLine("NAMES %s" % channel)
		return d

	def irc_RPL_NAMREPLY(self, prefix, params):
		channel = params[2].lower()
		nicklist = params[3].split('%/')

		if channel not in self._namescallback:
			return

		n = self._namescallback[channel][1]
		n += nicklist

	def irc_RPL_ENDOFNAMES(self, prefix, params):
		channel = params[1].lower()
		if channel not in self._namescallback:
			return

		callbacks, namelist = self._namescallback[channel]
		for cb in callbacks:
			cb.callback(namelist)

		del self._namescallback[channel]





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

def escape(string):
	return string.replace('\\', '\\\\').replace('"', '\\\"')

def irccolorize(string):
	colors = {
		'a': '5', 'b': '15', 'c': '0', 'd': '9', 'e': '14', 'f': '8',
		'g': '4', 'h': '12', 'i': '7', 'j': '0', 'k': '8', 'l': '4',
		'm': '14', 'n': '11', 'o': '7', 'p': '3', 'q': '3', 'r': '5',
		's': '5', 't': '13', 'u': '14', 'v': '11'
		}
	
	codes = re.finditer('(\x1c[A-Va-v])', string)
	for code in codes:
		codestr = code.group(1)
		string = string.replace(codestr, ''.join(['\x03', colors[codestr[1].lower()]]), 1)

	return string

def main(cmd = None):
	# Check to see if we actually have a valid command
	if not cmd:
		print "You need to run hissy with a command. (e.g. zandronum-server)"
		return 1

	log.startLogging(sys.stdout)

	zandronum = zandronumProcessProtocol()
	hissyirc = HissyIRCClientFactory('#fnf')

	hissyirc.process = zandronum
	zandronum.irc = hissyirc

	# Connect to IRC
	reactor.connectTCP('mancubus.zandronum.com', 6667, hissyirc)

	# Start the zandronum server
	path = os.path.normpath(os.getcwd() + '/' + cmd[0])
	head, tail = os.path.split(path)
	log.msg("Spawning {0}...".format(' '.join([path] + cmd[1:])))
	reactor.spawnProcess(zandronum, path, [path] + cmd[1:])
	reactor.run()

if __name__ == '__main__':
	main(sys.argv[1:])