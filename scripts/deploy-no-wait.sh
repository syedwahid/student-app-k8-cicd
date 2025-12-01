#!/bin/bash
set -e

echo "🚀 Quick Deploy - No waiting for MySQL..."

echo "📋 Creating namespace..."
kubectl apply -f k8s/namespace.yaml

echo "🔐 Applying secrets..."
kubectl apply -f k8s/secrets.yaml

echo "📝 Applying configmaps..."
kubectl apply -f k8s/configmap.yaml

echo "🗄️ Deploying MySQL (will start in background)..."
kubectl apply -f k8s/mysql/deployment-simple.yaml
kubectl apply -f k8s/mysql/service.yaml

echo "🔧 Deploying Backend..."
kubectl apply -f k8s/backend/

echo "🎨 Deploying Frontend..."
kubectl apply -f k8s/frontend/

echo "⏳ Waiting for frontend to be ready..."
kubectl wait --for=condition=ready pod -l app=frontend -n student-app --timeout=120s

echo "✅ Quick deployment completed!"
echo ""
echo "📊 Application Status:"
kubectl get all -n student-app

echo ""
echo "🌐 Frontend should be available at: http://localhost:30008"
echo "💡 Backend will fail until MySQL is ready (check with: kubectl logs -l app=backend -n student-app)"