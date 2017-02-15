#!env bash

set -e

eval $(docker-machine env node-1)


docker build -t scheduler .

docker-machine ssh node-1 "docker save scheduler" | docker-machine ssh node-2 "docker load"; 

# docker service rm fun-swarm-scheduler

export DOCKER_SERVICE_PREFER_OFFLINE_IMAGE=1
docker service create --name fun-swarm-scheduler \
    --constraint=node.role==manager \
    --publish 8080:8484 \
    --mount type=bind,source=/var/run/docker.sock,target=/var/run/docker.sock \
    --network fun-swarm \
    scheduler:latest


