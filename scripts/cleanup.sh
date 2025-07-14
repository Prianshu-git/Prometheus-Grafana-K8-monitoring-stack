#!/bin/bash
set -e

echo "Uninstalling Prometheus stack..."
helm uninstall prometheus || true

echo "Deleting CPU stress pod..."
kubectl delete -f manifests/cpu-stress.yaml --ignore-not-found

echo "Deleting Nginx deployment..."
kubectl delete -f manifests/nginx.yaml --ignore-not-found

echo "Deleting Memory hog job..."
kubectl delete -f manifests/memory-hog.yaml --ignore-not-found

minikube delete
