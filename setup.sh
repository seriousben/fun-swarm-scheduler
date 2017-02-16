#!env bash

set -e

#
# Env:
#   DOCKER_SERVICE_PREFER_OFFLINE_IMAGE=1 let the docker engine prefer local images over registry images
#

#docker-machine create -d virtualbox --engine-env DOCKER_SERVICE_PREFER_OFFLINE_IMAGE=1 node-1 &
docker-machine create -d virtualbox node-1 &
NODE1_PID=$!
#docker-machine create -d virtualbox --engine-env DOCKER_SERVICE_PREFER_OFFLINE_IMAGE=1 node-2 &
docker-machine create -d virtualbox node-2 &
NODE2_PID=$!

wait $NODE1_PID
wait $NODE2_PID

docker-machine ls

# Init Manager
eval $(docker-machine env node-1)
docker swarm init --advertise-addr $(docker-machine ip node-1) --listen-addr $(docker-machine ip node-1):2377

TOKEN=$(docker swarm join-token -q worker)
echo "TOKEN=$TOKEN"

function joinSwarm() {
	nodeName=$1
	eval $(docker-machine env $nodeName)
	docker swarm join --token $TOKEN $(docker-machine ip node-1):2377
}

joinSwarm "node-2"

eval $(docker-machine env node-1)

docker node ls
docker network create --driver overlay fun-swarm
docker network ls
