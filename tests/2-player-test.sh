#!/bin/bash

[[ -z $1 ]] && c1=archer || c1=$1
[[ -z $2 ]] && c2=archer || c2=$2

./run.sh server $c1 &
sleep 0.5 # this is required, so that the server is always the first!
./run.sh client $c2 "127.0.0.1" &

read

pkill -9 love
