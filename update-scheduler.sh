#!env bash

set -e

eval $(docker-machine env node-1)

docker build -t scheduler .

docker-machine ssh node-1 "docker save scheduler" | docker-machine ssh node-2 "docker load"; 

docker service update --force --image scheduler:latest fun-swarm-scheduler 

