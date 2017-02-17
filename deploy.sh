#!env bash

set -e

eval $(docker-machine env node-1)

#
# Deploying nginx as a test app
#
docker pull nginx:latest
# Hack to not use a registry to share images across the swarm nodes
docker-machine ssh node-1 "docker save nginx:latest" | docker-machine ssh node-2 "docker load"; 
docker service create --name nginx \
       --hostname="{{.Service.Name}}-{{.Task.Slot}}" \
       --publish 80 \
       --replicas 2 \
       --network fun-swarm \
       nginx:latest

#
# Deploying scheduler
#
docker build -t scheduler .
# Hack to not use a registry to share images across the swarm nodes
docker-machine ssh node-1 "docker save scheduler:latest" | docker-machine ssh node-2 "docker load"; 

# docker service rm fun-swarm-scheduler

docker service create --name fun-swarm-scheduler \
       --constraint=node.role==manager \
       --publish 8484 \
       --mount type=bind,source=/var/run/docker.sock,target=/var/run/docker.sock \
       --network fun-swarm \
       scheduler:latest
