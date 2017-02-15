# Fun Swarm Scheduler

This repo is a POC around having a swarm service responsible for scheduling new services and scaling existing services.


## Setup

 * `setup.sh`: Create the docker-machine, the swarm and the overlay network.
 * `deploy.sh`: Deploy testing service
 * `deploy-scheduler.sh`: Deploy the scheduler
 * `update-scheduler.sh`: Updates the scheduler running on swarm

## Usage

 * `docker-machine ip node-1`: IP address for the manager
 * `http://192.168.99.101:8080/health`: Lists running services
 * `http://192.168.99.101:8080/create`: Create a new service


