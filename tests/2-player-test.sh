#!/bin/bash

./run.sh server u1 &
sleep 0.5 # this is required, so that the server is always the first!
./run.sh client u1 "127.0.0.1" &

read

pkill -9 love
