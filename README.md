# Fun Swarm Scheduler

This repo is a POC/Playground around having a swarm service responsible for scheduling and scaling services.


## Setup

 * `setup.sh`: Create the docker-machine, the swarm and the overlay network
 * `deploy.sh`: Deploy testing service and scheduler
 * `update-scheduler.sh`: Updates the scheduler running on swarm
 * `cleanup.sh`: Destroy docker-machine nodes

## Usage

 * `docker-machine ip node-1`: IP address for the manager
 * `$(docker-machine ip node-1):$(docker service inspect --format="{{ (index .Endpoint.Ports 0).PublishedPort }}" scheduler)/health`: Lists running services
 * `$(docker-machine ip node-1):$(docker service inspect --format="{{ (index .Endpoint.Ports 0).PublishedPort }}" scheduler)/create`: Create a new service


## POC Q&A

With your Swarm running (`./setup.sh && ./deploy.sh`)

### Can I contact Swarm locally?

1. Run the scheduler

  ```console
  # Export the docker connection environment variables
  $ eval $(docker-machine env node-1)

  # Install deps
  $ govendor sync

  # Run the scheduler
  $ go run main.go
  ```

2. Check the scheduler health

  ```console
  $ curl http://localhost:8484/health
  ```

3. Ask the schduler to create a service

  ```console
  $ curl http://localhost:8484/create
  ```

4. Make sure the service exists

  ```console
  $ docker service ls
  ```

### Can I contact Swarm from Docker for MacOS?

1. Unset previously set variables to make sure you are talking to your docker for mac

  ```console
  $ unset $(cat manager.env.default | sed 's/=.*//')
  ```

2. Setup the manager.env file

  ```console
  # Create the manager.env in a format that docker expects
  $ docker-machine env node-1 | sed "s/\"//g;s/export //g;s/^#.*//;s/_PATH=.*/_PATH=\/ca\/manager\//" > manager.env
  ```

3. Run the scheduler in docker

  ```console
  # Run!
  $ docker run --env-file manager.env -v /Users/brh/.docker/machine/machines/node-1/:/ca/manager scheduler
  ```

4. Export the swarm env variables

  ```console
  $ eval $(docker-machine env node-1)
  ```

5. Check the scheduler health

  ```console
  $ curl $(docker-machine ip node-1):$(docker service inspect --format="{{ (index .Endpoint.Ports 0).PublishedPort }}" scheduler)/health
  ```

6. Ask the scheduler to create a service

  ```console
  $ curl $(docker-machine ip node-1):$(docker service inspect --format="{{ (index .Endpoint.Ports 0).PublishedPort }}" scheduler)/create
  ```

7. Make sure the service exists

  ```console
  $ docker service ls
  ```

### Can I access a specific Service Task?

1. Edit a specific task

  ```console
  $ docker-machine ssh node-2
  
                          ##         .
                    ## ## ##        ==
                ## ## ## ## ##    ===
            /"""""""""""""""""\___/ ===
        ~~~ {~~ ~~~~ ~~~ ~~~~ ~~~ ~ /  ===- ~~~
            \______ o           __/
              \    \         __/
                \____\_______/
   _                 _   ____     _            _
  | |__   ___   ___ | |_|___ \ __| | ___   ___| | _____ _ __
  | '_ \ / _ \ / _ \| __| __) / _` |/ _ \ / __| |/ / _ \ '__|
  | |_) | (_) | (_) | |_ / __/ (_| | (_) | (__|   <  __/ |
  |_.__/ \___/ \___/ \__|_____\__,_|\___/ \___|_|\_\___|_|
  Boot2Docker version 1.13.1, build HEAD : b7f6033
  Docker version 1.13.1, build 092cba3
  docker@node-2:~$

  # Exec against a running nginx service task running on the node-2
  $ docker exec -it $(docker ps --format="{{.ID}}") /bin/bash

  # Change content served by nginx
  $ echo "hello world" > /usr/share/nginx/html/index.html
  ```

2. Test the change on the service endpoint

  Run this multiple times until you hit the nginx instance with the changed index.html.

  ```console
  $ curl $(docker-machine ip node-1):$(docker service inspect --format="{{ (index .Endpoint.Ports 0).PublishedPort }}" nginx)
  hello world
  ```

3. Access the changed task directly

  ```console
  $ eval $(docker-machine env node-1)
  
  # Setup a busybox service for utility tools (Here since we allow prefer local images we need to push the image)
  $ docker pull busybox:latest
  $ docker-machine ssh node-1 "docker save scheduler:latest" | docker-machine ssh node-2 "docker load";
  
  # On swarm on service can access the overlay network
  $ docker service create --name busybox --constraint=node.role==manager --network fun-swarm busybox sleep 3000
  
  # SSH to the manager
  $ docker-machine ssh node-1

  # Show all the tasks hostnames within the overlay network
  $ docker service ps busybox
  $ docker exec -it busybox.1.zempjamvt6y29mrd0fwo3mzn5 nslookup tasks.


  # Connect to the specific task
  $ docker exec -it busybox.1.zempjamvt6y29mrd0fwo3mzn5 wget -O - nginx.1.z25m0oj8k43a6inxb0m7ov37f.fun-swarm
  hello world 
  ```

  Although not possible to access a task from outside the overlay network. This proves that it would be possible to access the task if it was served through a reverse proxy.

## Some resources

### General

 * [Networking in Swarm](https://docs.docker.com/engine/swarm/networking/): https://docs.docker.com/engine/swarm/networking/

### Reverse Proxies

 * [Traefik in swarm mode](https://docs.traefik.io/user-guide/swarm-mode/): https://docs.traefik.io/user-guide/swarm-mode/
  * Proxy runs on manager nodes
  * Proxy polls (In Docker 1.13.1 - Swarm is still not publishing events as streams)
  * App Proxy attributes stored as labels on each service
 * [Docker Flow Proxy](http://proxy.dockerflow.com/swarm-mode-auto/): http://proxy.dockerflow.com/swarm-mode-auto/
  * Proxy can scale and be deployed to any nodes (not only on manager) without any KV store
  * The Proxy itself does NOT poll, it relies on another component to tell it what services are running.
  * Requires another container running on the manager nodes that keeps proxies in sync with the services running
   * https://github.com/vfarcic/docker-flow-swarm-listener
