#!/usr/bin/python3 -B

import asyncio
from time import sleep

DELAY_MS=20

import sys
import socket

def usage():
	print("Usage: ./delayman.py <server-port> <delayman-port>")

async def send_delayed(s, data, target_port):
	sleep(DELAY_MS / 1000)
	s.sendto(data, ("127.0.0.1", target_port))

def main():
	if len(sys.argv) != 3:
		usage()
		sys.exit(1)
	server_port = int(sys.argv[1])
	delayman_port = int(sys.argv[2])

	loop = asyncio.get_event_loop()

	s = None
	try:
		s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
		s.bind(("127.0.0.1", delayman_port))

		client_port = None

		while True:
			data, addr = s.recvfrom(2000)
			port = addr[1]
			if client_port == None and port != server_port:
				client_port = port

			if port == server_port:
				target_port = client_port
			elif port == client_port:
				target_port = server_port
			else:
				print("received packet from strange port: {}".format(port))
				continue
			loop.run_until_complete(send_delayed(s, data, target_port))
	except:
		if s != None:
			s.close()
		loop.close()

main()
