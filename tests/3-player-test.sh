#!/bin/bash

cd ..

./run.sh server u1 &
sleep 0.5 # this is required, so that the server is always the first!
./run.sh client u1 "127.0.0.1" &
sleep 1
./run.sh client u1 "127.0.0.1"
