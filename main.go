package main

import (
	"context"
	"fmt"
	"log"
	"net/http"
	"os"

	"github.com/docker/docker/api/types"
	"github.com/docker/docker/api/types/swarm"
	"github.com/docker/docker/client"
)

type ContainerTemplate struct {
	Image  string
	Name   string
	Labels []string
}

type ContainerInstance struct {
	Image string
	Name  string
}

type Manager struct {
	managerClient *client.Client
}

func (mng *Manager) ContainerList() ([]types.Container, error) {
	containers, err := mng.managerClient.ContainerList(context.Background(), types.ContainerListOptions{})

	return containers, err
}

func (mng *Manager) NodeInspect(nodeID string) (swarm.Node, error) {
	nodeInspect, _, err := mng.managerClient.NodeInspectWithRaw(context.Background(), nodeID)
	return nodeInspect, err
}

func (mng *Manager) NodeList() ([]swarm.Node, error) {
	nodes, err := mng.managerClient.NodeList(context.Background(), types.NodeListOptions{})
	return nodes, err
}

func (mng *Manager) ServiceCreate() (types.ServiceCreateResponse, error) {
	numService += 1

	endpointSpec := swarm.EndpointSpec{
		Mode: "vip",
	}

	serviceSpec := swarm.ServiceSpec{
		Annotations: swarm.Annotations{
			Name: fmt.Sprintf("service-%v", numService),
			Labels: map[string]string{
				"traefik.backend":       "nginx",
				"traefik.port":          "80",
				"traefik.frontend.rule": "PathPrefixStrip:/nginx",
			},
		},
		TaskTemplate: swarm.TaskSpec{
			ContainerSpec: swarm.ContainerSpec{
				Image: "nginx:latest",
			},
			Networks: []swarm.NetworkAttachmentConfig{{
				Target: "fun-swarm-scheduler_default",
			}},
		},
		EndpointSpec: &endpointSpec,
	}
	createResponse, err := mng.managerClient.ServiceCreate(context.Background(), serviceSpec, types.ServiceCreateOptions{})
	return createResponse, err
}

func (mng *Manager) ServiceUpdate(serviceID string) (types.ServiceUpdateResponse, error) {
	updateResponse, err := mng.managerClient.ServiceUpdate(context.Background(), serviceID, swarm.Version{}, swarm.ServiceSpec{}, types.ServiceUpdateOptions{})
	return updateResponse, err
}

func (mng *Manager) ServiceList() ([]swarm.Service, error) {
	services, err := mng.managerClient.ServiceList(context.Background(), types.ServiceListOptions{})
	return services, err
}

func NewManager() (*Manager, error) {
	managerClient, err := client.NewEnvClient()
	if err != nil {
		panic(err)
	}
	return &Manager{
		managerClient: managerClient,
	}, nil
}

func serviceListHandler(w http.ResponseWriter, r *http.Request) {
	h, _ := os.Hostname()
	log.Printf("serviceList start on %s", h)
	createResponse, err := manager.ServiceList()
	if err != nil {
		panic(err)
	}
	fmt.Fprintf(w, "serviceList ran on %s: %+v", h, createResponse)
	log.Printf("serviceList done on %s: %+v", h, createResponse)
}

func createServiceHandler(w http.ResponseWriter, r *http.Request) {
	h, _ := os.Hostname()
	log.Printf("createService start on %s", h)
	createResponse, err := manager.ServiceCreate()
	if err != nil {
		panic(err)
	}
	fmt.Fprintf(w, "createService ran on %s: %+v", h, createResponse)
	log.Printf("createService done on %s: %+v", h, createResponse)
}

var (
	manager    *Manager
	numService int
)

func main() {
	mng, err := NewManager()
	if err != nil {
		panic(err)
	}

	containers, err := mng.ContainerList()
	if err != nil {
		panic(err)
	}

	for _, container := range containers {
		fmt.Printf("Manager container: %s %s\n", container.ID[:10], container.Image)
	}

	manager = mng

	http.HandleFunc("/create", createServiceHandler)
	http.HandleFunc("/health", serviceListHandler)

	http.ListenAndServe(":8484", nil)
}
