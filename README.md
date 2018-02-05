# Ruby-Kubernetes
Dockerize ruby and rails app , publish and scale with K8s

# Lab Environment

* Ubuntu 16.10
* Docker version 18.01.0-ce
* Docker-compose 1.16.1
* [Minikube](https://kubernetes.io/docs/tasks/tools/install-minikube/) v0.25.0
   * Kubernetes 1.8.0
   * kubelet 1.8.0
   * docker 17.09.0-ce
* GNU Make 
* vm-driver KVM 2.5.0

# Tune Lab Environment (Only for minikube part)

 minikube start --kubernetes-version='v1.8.0' --vm-driver=kvm
 
 be sure that kubectl point to the minikube by the following command:
 
 kubectl config current-context 
 
 Change docker host to the minikube VM
 
 ```
 eval $(minikube docker-env)
 ```
 
 Rebuild the images in the local repo of minikube

 ```
 make minikube-image
 ```
 


# Docker-compose 
To build,initialize postgres and run the docker-compose stack , run the following command:
```
make dcompose-deploy
```

To clean the docker-compose containers and volumes , run the following command:

```
make dcompose-clean
```

# Kubernetes-Cluster

To initialize the project pods on kubernetes , run the following command:

```
make deploy
```

To clean the environment and delete all resource , run the following command:
```
make clean
```
