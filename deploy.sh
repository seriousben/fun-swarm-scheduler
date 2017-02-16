#!env bash

set -e

eval $(docker-machine env node-1)

#
# Deploying nginx as a test app
#
docker pull nginx:latest
# Hack to not use a registry to share images across the swarm nodes
docker-machine ssh node-1 "docker save nginx:latest" | docker-machine ssh node-2 "docker load"; 
docker service create --name hello \
       --hostname="{{.Service.Name}}-{{.Task.Slot}}" \
       --publish 8080:80 \
       --replicas 2 \
       --network fun-swarm \
       nginx:latest

#
# Change the html served by one container to fake a stateful service
#
# docker-machine ssh node-2
# docker exec -it nginx-container-id /bin/bash
#
# cat "HELLO" > /usr/share/nginx/html/index.html
# nginx -s reload
#
# docker-machine ssh node-1
#
# docker service create --name util --constraint=node.role==manager --network fun-swarm busybox sleep 3000
# docker exec -it util.1.zempjamvt6y29mrd0fwo3mzn5 nslookup tasks.hello
# docker exec -it util.1.zempjamvt6y29mrd0fwo3mzn5 wget -O - hello.1.z25m0oj8k43a6inxb0m7ov37f.fun-swarm
#
# Proves that a specific task can be accessed allowing future reverse-proxy.
#


#
# Deploying scheduler
#
docker build -t scheduler .
# Hack to not use a registry to share images across the swarm nodes
docker-machine ssh node-1 "docker save scheduler:latest" | docker-machine ssh node-2 "docker load"; 

# docker service rm fun-swarm-scheduler

docker service create --name fun-swarm-scheduler \
       --constraint=node.role==manager \
       --publish 8081:8484 \
       --mount type=bind,source=/var/run/docker.sock,target=/var/run/docker.sock \
       --network fun-swarm \
       scheduler:latest
