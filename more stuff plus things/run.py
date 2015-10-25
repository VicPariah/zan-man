#!/usr/bin/env python
from sys import argv, stdout
from os import listdir
from subprocess import call
from string import split, strip

try:
	if argv[1] == 'start':
		stdout.write('Starting all servers...\n')
		for file in listdir('.'):
			if '.sh' in file:
				try:
					screenid = split(file,'-')[-1]
					stdout.write('%s... ' % file)
					call(['screen', '-dmS', screenid.strip('.sh'), './'+file])
					stdout.write('DONE\n')
				except IndexError: stdout.write('FAILED (no server number in file: %s)' % file)
		stdout.write('Script finished without problem.\n')
	elif argv[1] == 'stop':
		stdout.write('Killing all servers... ')
		call(['pkill', '-9', 'zandronum-serve'])
		stdout.write('DONE\n')
	else:
		raise IndexError ('Unknown Command')
except IndexError:
	print '%s start' % argv[0]
	print '%s stop' % argv[0]
