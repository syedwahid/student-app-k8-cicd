#!/bin/bash
echo "🔍 Troubleshooting Student App Deployment..."

echo "1. Checking cluster status..."
kubectl cluster-info

echo "2. Checking all namespaces..."
kubectl get namespaces

echo "3. Checking all pods in student-app namespace..."
kubectl get pods -n student-app -o wide

echo "4. Checking services..."
kubectl get services -n student-app

echo "5. Checking pod details..."
for pod in $(kubectl get pods -n student-app -o name); do
    echo "=== $pod ==="
    kubectl describe -n student-app $pod | grep -A 5 "Status:"
done

echo "6. Checking logs..."
for pod in $(kubectl get pods -n student-app -o name); do
    echo "=== Logs for $pod ==="
    kubectl logs -n student-app $pod --tail=10
done

echo "7. Checking events..."
kubectl get events -n student-app --sort-by='.lastTimestamp'