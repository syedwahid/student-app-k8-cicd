#!/bin/bash
set -e

echo "🚀 Deploying Student App to Kubernetes..."

# Build and load images first
echo "🏗️ Building and loading Docker images..."
./scripts/build-images.sh

# Clean up any existing deployments first
echo "🧹 Cleaning up any existing deployments..."
kubectl delete -f k8s/backend/ 2>/dev/null || true
kubectl delete -f k8s/frontend/ 2>/dev/null || true
kubectl delete -f k8s/mysql/ 2>/dev/null || true

# Apply all Kubernetes manifests in order
echo "📋 Creating namespace..."
kubectl apply -f k8s/namespace.yaml

echo "🔐 Applying secrets..."
kubectl apply -f k8s/secrets.yaml

echo "📝 Applying configmaps..."
kubectl apply -f k8s/configmap.yaml

echo "🗄️ Deploying MySQL..."
kubectl apply -f k8s/mysql/deployment-simple.yaml
kubectl apply -f k8s/mysql/service.yaml

echo "⏳ Waiting for MySQL to start (this can take 2-3 minutes)..."
echo "📦 MySQL is initializing. This is normal for the first time..."

# Wait for pod to be created first
while [[ $(kubectl get pods -l app=mysql -n student-app -o 'jsonpath={..status.phase}') != "Running" ]]; do
    echo "⏰ MySQL pod is starting up..."
    kubectl get pods -l app=mysql -n student-app
    sleep 30
done

echo "✅ MySQL pod is running! Waiting for database to be ready..."
kubectl wait --for=condition=ready pod -l app=mysql -n student-app --timeout=300s

echo "🎉 MySQL is ready! Proceeding with backend and frontend..."

echo "🔧 Deploying Backend..."
kubectl apply -f k8s/backend/

echo "🎨 Deploying Frontend..."
kubectl apply -f k8s/frontend/

echo "⏳ Waiting for backend to be ready..."
kubectl wait --for=condition=ready pod -l app=backend -n student-app --timeout=180s

echo "⏳ Waiting for frontend to be ready..."
kubectl wait --for=condition=ready pod -l app=frontend -n student-app --timeout=180s

echo "✅ Deployment completed!"
echo ""
echo "📊 Application Status:"
kubectl get all -n student-app

echo ""
echo "🌐 Access URLs:"
echo "   Backend API:  http://localhost:30007"
echo "   Frontend App: http://localhost:30008"