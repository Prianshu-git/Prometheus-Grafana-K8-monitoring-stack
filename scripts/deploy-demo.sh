#!/bin/bash
set -e

echo "Deploying CPU stress pod..."
kubectl apply -f manifests/cpu-stress.yaml

echo "Deploying Nginx server..."
kubectl apply -f manifests/nginx.yaml

echo "Deploying Memory hog job..."
kubectl apply -f manifests/memory-hog.yaml