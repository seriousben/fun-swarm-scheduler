#!env bash

set -e

eval $(docker-machine env node-1)

# Test app
docker service create --name hello2 --publish 80 --network fun-swarm nginx
