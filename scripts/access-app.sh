#!/bin/bash
echo "🎓 Student Management App - Access Guide"
echo "========================================"

# Kill any existing port-forwards
pkill -f "kubectl port-forward" 2>/dev/null || true

echo ""
echo "🚀 Starting application access..."

# Start port-forwards
echo "🔧 Starting backend on port 30001..."
kubectl port-forward -n student-app service/backend-service 30001:3000 &

echo "🎨 Starting frontend on port 8888..."
kubectl port-forward -n student-app service/frontend-service 8888:80 &

sleep 5

echo ""
echo "🧪 Testing connections..."
echo "Backend API:"
curl -s http://localhost:30001/api/health | jq '.status' || echo "Backend not ready"

echo ""
echo "Frontend:"
curl -s -I http://localhost:8888 | head -1 || echo "Frontend not ready"

echo ""
echo "✅ Application is now running!"
echo ""
echo "🌐 ACCESS URLs:"
echo "   Frontend (UI):    http://localhost:8888"
echo "   Backend (API):    http://localhost:30001/api"
echo ""
echo "🔍 TEST ENDPOINTS:"
echo "   Health Check:     curl http://localhost:30001/api/health"
echo "   List Students:    curl http://localhost:30001/api/students"
echo ""
echo "📚 DEMO FEATURES:"
echo "   • View student list with search"
echo "   • Add new students"
echo "   • Edit existing students" 
echo "   • Delete students"
echo "   • Real-time statistics"
echo ""
echo "⏹️  To stop: Press Ctrl+C or run: pkill -f 'kubectl port-forward'"
echo ""
echo "💡 TROUBLESHOOTING:"
echo "   If data doesn't load: Clear browser cache (Ctrl+Shift+R)"
echo "   Check browser console (F12) for any errors"
echo ""
echo "🎯 Happy Learning!"
