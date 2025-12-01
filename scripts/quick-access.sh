#!/bin/bash
# Quick access script for Student Management App
echo "🚀 Quick Access - Student Management App"

# Kill existing port-forwards
pkill -f "kubectl port-forward" 2>/dev/null

# Start new port-forwards
kubectl port-forward -n student-app service/backend-service 30001:3000 &
kubectl port-forward -n student-app service/frontend-service 8888:80 &

echo "⏳ Starting services..."
sleep 5

echo ""
echo "✅ Ready! Access your application:"
echo "   🌐 UI: http://localhost:8888"
echo "   🔧 API: http://localhost:30001/api/health"
echo ""
echo "🛑 To stop: pkill -f 'kubectl port-forward'"
