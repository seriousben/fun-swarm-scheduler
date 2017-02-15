#!env bash

set -e

docker-machine rm node-1 -y &
NODE1_PID=$!
docker-machine rm node-2 -y &
NODE2_PID=$!

wait $NODE1_PID
wait $NODE2_PID
 
docker-machine ls
