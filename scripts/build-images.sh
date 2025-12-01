#!/bin/bash
set -e

echo "🏗️ Building Docker images..."

echo "🔧 Building backend image..."
cd app/backend
docker build -t student-backend:latest .
cd ../..

echo "🎨 Building frontend image..."
cd app/frontend  
docker build -t student-frontend:latest .
cd ../..

echo "📦 Loading images into Kind cluster..."
kind load docker-image student-backend:latest --name student-app
kind load docker-image student-frontend:latest --name student-app

echo "✅ Images built and loaded successfully!"
echo ""
echo "📋 Available images:"
docker images | grep student-