<div align="center">
<img width="500" height="500" alt="Gemini_Generated_Image_3k6m4w3k6m4w3k6m-removebg-preview" src="https://github.com/user-attachments/assets/568efb5e-cd79-4cad-862c-e261156f9178" />
</div>

![Ubuntu](https://img.shields.io/badge/OS-Ubuntu%2022.04-orange?logo=ubuntu)
![Minikube](https://img.shields.io/badge/Minikube-v1.36.0-blue?logo=kubernetes)
![Kubernetes](https://img.shields.io/badge/Kubernetes-1.33.1-326ce5?logo=kubernetes)
![Helm](https://img.shields.io/badge/Helm-3.x-blue?logo=helm)
![kubectl](https://img.shields.io/badge/Kubectl-v1.26+-lightblue?logo=linux)
![CRI-Dockerd](https://img.shields.io/badge/CRI--Dockerd-enabled-brightgreen?logo=docker)
![CNI Plugins](https://img.shields.io/badge/CNI-Plugins-green?logo=linux)
![Prometheus](https://img.shields.io/badge/Monitoring-Prometheus-orange?logo=prometheus)
![Grafana](https://img.shields.io/badge/Dashboard-Grafana-F46800?logo=grafana)
![Alertmanager](https://img.shields.io/badge/Alerts-Alertmanager-red?logo=prometheus)
![NGINX](https://img.shields.io/badge/Webserver-NGINX-009639?logo=nginx)
![BusyBox](https://img.shields.io/badge/Container-BusyBox-blue?logo=docker)
![Polinux/Stress](https://img.shields.io/badge/LoadTest-polinux%2Fstress-yellow?logo=docker)


## Technologies used

- **Minikube** (None driver with cri-dockerd)
- **CNI Plugins** (for container networking,as my dockernetwork bridge is not responding)
- **Helm + Kube Prometheus** Stack
- **Prometheus + Alertmanager**
- **Grafana**
- **Custom Workloads**
  - CPU Stress (polinux/stress)
  - Memory Hog (busybox)
  - NGINX web serve

## Installation 
Ensure this file stucture after cloning the project

```bash
minikube-prometheus-grafana-demo/
├── charts/
├── manifests/
│   ├── cpu-stress.yaml
│   ├── nginx.yaml
│   └── memory-hog.yaml
├── scripts/
│   ├── start.sh
│   ├── deploy-demo.sh
│   ├── access.sh
│   └── cleanup.sh
├── README.md
└── .gitignore
```
cri-dockerd is used to bridge Kubernetes with Docker to run pods defined in this project.
Install by cloning their repository

```bash
git clone https://github.com/Mirantis/cri-dockerd
cd cri-dockerd
go build -o bin/cri-dockerd
sudo install -o root -g root -m 0755 bin/cri-dockerd /usr/local/bin/cri-dockerd
```
To start the service 
```bash 
sudo cp packaging/systemd/* /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable cri-docker.service
sudo systemctl start cri-docker.service
```

The files inside the *manifests/* are for creating Kubernetes pods with containers like nginx,stress and busybox for defining the services.Each pod may run one or more containers.

**cpu-stress.yaml** Generates consistent CPU load for demonstrating CPU graphs in Grafana.

**nignx.yaml** Creates a basic NGINX web server for showing network I/O and pod restarts.

**memory-hog.yaml** Creates a memory-intensive job that sleeps for simulating memory spikes and testing alert thresholds.

The files in *scripts/* are regular shell scripts with names respective to their functions

**scripts/start.sh**

```bash
minikube start --cpus=4 --memory=8192
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm install prometheus prometheus-community/kube-prometheus-stack
```
Minikube starts a local Kubernetes cluster with specified resources.Helm provides a simple, declarative way to install and manage Prometheus and Grafana on Kubernetes using Helm Charts which are packaged applications that include templated Kubernetes manifests and default configuration values which covers things like monitoring,resource definitions,cluster object state as metrics,etc.

**scripts/deploy-demo.sh**

```bash
kubectl apply -f manifests/cpu-stress.yaml
kubectl apply -f manifests/nginx.yaml
kubectl apply -f manifests/memory-hog.yaml
```
It applies all the kubernetes manifest files using kubectl.When we deploy test workloads like cpu-stress, nginx, and memory-hog using kubectl apply, Kubernetes schedules these pods and delegates container execution to Docker via the CRI-Dockerd shim, ensuring compatibility with Kubernetes even after Docker support was deprecated. Simultaneously, the CNI plugin assigns each pod a virtual IP from an internal subnet and sets up virtual networking that allows seamless pod-to-pod and service-to-pod communication. This enables Prometheus, installed via Helm, to discover and scrape metrics from the pods through ServiceMonitor definitions that resolve DNS and route traffic over the CNI-managed overlay network.

**scripts/access.sh**

```bash
kubectl port-forward svc/prometheus-grafana 3000:80
kubectl port-forward svc/prometheus-kube-prometheus-prometheus
```
The kubectl port-forward commands work by exposing a service or pod running inside your Kubernetes cluster to your local machine, making it accessible via localhost.`svc/prometheus-grafana` refers to a kubernetes service that routes to the pods running Grafana and port 80 is the service port inside the cluster.`3000:80` Forwards traffic from your localhost:3000 → Service's port 80 → Grafana Pod.

You can access your Grafana Dashboard now
at: http://localhost:3000 
`username:admin`
`password:prom-operator`

Additionally 
 you can use forwarding such as localhost:9090 → Service: prometheus-kube-prometheus-prometheus (port auto-mapped, defaults to 9090) to access prometheus UI.
 
```bash
kubectl port-forward svc/prometheus-kube-prometheus-prometheus 9090
```
Prometheus UI at:http://localhost:9090

**scripts/cleanup.sh**

Tears everything down 

```bash
helm uninstall prometheus
kubectl delete -f manifests/
minikube delete
```
## Handy Debugs
|                 |                                                     |                                              |
| ------------------------------------ | --------------------------------------------------------------------------- | --------------------------------------------------------------- |
| **Pod CPU & Memory Usage**           | `kubectl top pod -A`                                                        | Shows real-time CPU/Memory of all pods (needs `metrics-server`) |
| **Node CPU & Memory Usage**          | `kubectl top node`                                                          | Shows CPU/Memory usage per node                                 |
| **Live Watch on Resource Usage**     | `watch -n 2 kubectl top pod -A`                                             | Live updating resource metrics                                  |
| **Pod Restarts / Failures**          | `kubectl get pods -A --sort-by='.status.containerStatuses[0].restartCount'` | Lists pods with highest restart counts                          |
| **Detailed Pod Debug**               | `kubectl describe pod <pod> -n <ns>`                                        | Shows events, container status, reasons for failures            |
| **View Pod Logs**                    | `kubectl logs <pod>`<br>`kubectl logs -f <pod>`                             | Get logs (static or real-time) from container                   |
| **Multi-container Pods**             | `kubectl logs <pod> -c <container>`                                         | Get logs from a specific container                              |
| **Shell Into Pod**                   | `kubectl exec -it <pod> -- /bin/sh`                                         | Debug from inside the container                                 |
| **All Events (Chronological)**       | `kubectl get events --sort-by='.metadata.creationTimestamp'`                | Inspect warnings, OOMs, scheduling failures                     |
| **DNS Resolution Check**             | `kubectl exec <pod> -- nslookup kubernetes.default`                         | Tests internal DNS is working                                   |
| **Test Network Reachability**        | `kubectl exec <pod> -- curl <service>.<ns>.svc.cluster.local:<port>`        | Verifies service connectivity from inside cluster               |
| **List Network Policies**            | `kubectl get networkpolicy -A`                                              | Shows active network restrictions                               |
| **All Services (Debug Routing)**     | `kubectl get svc -A`<br>`kubectl describe svc <svc>`                        | Validate routing, ports, selectors                              |
| **All Ingress Routes**               | `kubectl get ingress -A`                                                    | Check external HTTP(S) entry points                             |
| **Pod IPs & Node Mapping**           | `kubectl get pods -o wide`                                                  | Shows IP, node, container info                                  |
| **Port Forward Service**             | `kubectl port-forward svc/<svc> <local>:<svc-port>`                         | Access a service locally via `localhost:<port>`                 |
| **Port Forward Pod**                 | `kubectl port-forward pod/<pod> <local>:<container-port>`                   | Same as above, but direct to pod                                |
| **Node Metrics via Node Exporter**   | `kubectl port-forward svc/prometheus-node-exporter 9100:9100 -n monitoring` | Access raw node metrics at `localhost:9100/metrics`             |
| **View Prometheus Targets**          | `kubectl port-forward svc/prometheus-kube-prometheus-prometheus 9090`       | Use Prometheus UI to debug scraping issues                      |
| **Grafana Dashboard Access**         | `kubectl port-forward svc/prometheus-grafana 3000:80`                       | Access monitoring dashboards on `localhost:3000`                |
| **SSH into Minikube VM**             | `minikube ssh`                                                              | Inspect system-level stats like disk and processes              |
| **Disk Usage** (Inside node)         | `df -h`                                                                     | View partition usage                                            |
| **Memory Usage** (Inside node)       | `free -m` or `top`                                                          | See available RAM and active processes                          |
| **Network Interfaces** (Inside node) | `ip a` or `ifconfig`                                                        | View pod bridges and node IPs                                   |
| **Cluster Component Status**         | `kubectl get componentstatuses`                                             | Status of etcd, scheduler, controller-manager                   |
| **List All Namespaces**              | `kubectl get ns`                                                            | Validate if workloads exist in correct namespaces               |
| **All Deployments & ReplicaSets**    | `kubectl get deploy,rs -A`                                                  | Monitor rollout status, scaling, replicas                       |
| **All Nodes & Conditions**           | `kubectl get nodes -o wide`<br>`kubectl describe node <node>`               | View allocatable resources, taints, disk pressure, etc.         |

## Support Material
