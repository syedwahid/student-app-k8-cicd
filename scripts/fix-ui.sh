#!/bin/bash
echo "🎯 Fixing UI Display Issues"
echo "==========================="

echo "1. 🛑 Stopping existing services..."
pkill -f "kubectl port-forward" 2>/dev/null
sleep 2

echo "2. 🔄 Rebuilding frontend with fixed app.js..."
eval $(minikube docker-env)
cd app/frontend
docker build -t student-frontend:latest .
cd ../..

echo "3. 🚀 Restarting frontend deployment..."
kubectl rollout restart deployment/frontend -n student-app

echo "4. ⏳ Waiting for frontend to be ready..."
kubectl wait --for=condition=ready pod -l app=frontend -n student-app --timeout=60s

echo "5. 🌐 Starting port-forward services..."
kubectl port-forward -n student-app service/backend-service 30001:3000 &
kubectl port-forward -n student-app service/frontend-service 8888:80 &

echo "6. ⏰ Waiting for services to start..."
sleep 10

echo "7. 🧪 Testing connections..."
echo "Backend API:"
curl -s http://localhost:30001/api/students | jq length
echo " students returned"

echo ""
echo "Frontend JavaScript:"
curl -s http://localhost:8888/app.js | grep "API_BASE_URL" | head -1

echo ""
echo "8. ✅ Fix complete!"
echo ""
echo "📋 Instructions:"
echo "   • Open http://localhost:8888"
echo "   • Press Ctrl+Shift+R to hard reload"
echo "   • Check browser console (F12) for messages"
echo "   • Look for: 'API Base URL: http://localhost:30001/api'"
echo ""
echo "If still not working, check browser console for errors."
