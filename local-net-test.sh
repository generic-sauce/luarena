#!/bin/bash

SERVER_PORT="3838"
DELAYMAN_PORT="3840"

./delayman.py $SERVER_PORT $DELAYMAN_PORT &
./run.sh server u1 $SERVER_PORT &
./run.sh client u1 "127.0.0.1" $DELAYMAN_PORT

pkill delayman.py
