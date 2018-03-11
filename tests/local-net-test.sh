#!/bin/bash

SERVER_PORT="3838"
DELAYMAN_PORT="3840"

./delayman.py $SERVER_PORT $DELAYMAN_PORT &
./run.sh server u1 $SERVER_PORT &
sleep 0.1 # this is required, so that the server is always the first!
./run.sh client u1 "127.0.0.1" $DELAYMAN_PORT

pkill delayman.py
