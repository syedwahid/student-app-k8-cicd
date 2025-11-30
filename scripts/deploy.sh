#!/bin/bash
set -e

echo "🚀 Deploying Student Management App to Kubernetes..."

# Check if tools are installed
if ! command -v kubectl &> /dev/null; then
    echo "❌ kubectl not found. Please install Kubernetes tools first."
    exit 1
fi

# Start Minikube if not running
if ! minikube status | grep -q "Running"; then
    echo "🔧 Starting Minikube..."
    minikube start --driver=docker
fi

# Set Docker environment to use Minikube's Docker daemon
eval $(minikube docker-env)

echo "📦 Building Docker images in Minikube environment..."

# Build backend image
echo "🔨 Building backend image..."
cd app/backend
docker build -t student-backend:latest .
cd ../..

# Build frontend image
echo "🎨 Building frontend image..."
cd app/frontend
docker build -t student-frontend:latest .
cd ../..

echo "✅ Images built successfully"

# Create namespace
echo "📁 Creating namespace..."
kubectl apply -f k8s/namespace.yaml

# Create secrets (even if we don't use MySQL, for completeness)
echo "🔐 Creating secrets..."
kubectl apply -f k8s/secrets.yaml

# Create configmaps
echo "⚙️ Creating configmaps..."
kubectl apply -f k8s/configmap.yaml

# Try to deploy MySQL (but don't fail if it has issues)
echo "🗄️ Attempting to deploy MySQL..."
kubectl apply -f k8s/mysql/ || echo "⚠️ MySQL deployment may have issues - using in-memory backend"

# Deploy Backend (uses in-memory storage)
echo "🔧 Deploying Backend..."
kubectl apply -f k8s/backend/

# Deploy Frontend
echo "🎨 Deploying Frontend..."
kubectl apply -f k8s/frontend/

# Wait for backend and frontend to be ready (don't wait for MySQL)
echo "⏳ Waiting for backend and frontend to be ready..."
kubectl wait --for=condition=ready pod -l app=backend -n student-app --timeout=120s
kubectl wait --for=condition=ready pod -l app=frontend -n student-app --timeout=120s

# Display deployment status
echo "📊 Deployment Status:"
kubectl get all -n student-app

echo ""
echo "✅ Deployment completed!"
echo "📝 Note: Using in-memory storage (no MySQL dependency)"
echo ""
echo "🌐 To access your application, run:"
echo "   ./scripts/access-app.sh"
