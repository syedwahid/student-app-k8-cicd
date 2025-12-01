#!/bin/bash

echo "🧹 Cleaning up Student Management App from Kubernetes..."

kubectl delete -f k8s/frontend/ --ignore-not-found=true
kubectl delete -f k8s/backend/ --ignore-not-found=true
kubectl delete -f k8s/mysql/ --ignore-not-found=true
kubectl delete -f k8s/configmap.yaml --ignore-not-found=true
kubectl delete -f k8s/secrets.yaml --ignore-not-found=true
kubectl delete -f k8s/namespace.yaml --ignore-not-found=true

# Kill any port-forward processes
pkill -f "kubectl port-forward" 2>/dev/null || true

echo "✅ Cleanup completed!"
