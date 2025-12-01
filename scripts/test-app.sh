#!/bin/bash
echo "🧪 Testing Student Management App"
echo "================================"

# Stop any existing port-forwards
pkill -f "kubectl port-forward" 2>/dev/null

# Start fresh port-forwards
kubectl port-forward -n student-app service/backend-service 30001:3000 &
kubectl port-forward -n student-app service/frontend-service 8888:80 &

sleep 5

echo ""
echo "🔍 Testing connections:"
echo "1. Backend API response:"
curl -s http://localhost:30001/api/students | jq length
echo " students"

echo ""
echo "2. Frontend app.js API_BASE_URL:"
curl -s http://localhost:8888/app.js | grep "API_BASE_URL"

echo ""
echo "3. Frontend accessibility:"
curl -s -I http://localhost:8888 | head -1

echo ""
echo "✅ Test complete!"
echo "🌐 Open http://localhost:8888 in your browser"
echo "💡 Use Ctrl+Shift+R if data doesn't load immediately"
