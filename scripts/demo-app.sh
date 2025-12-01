#!/bin/bash
echo "🎬 Student Management App - Live Demo"
echo "===================================="

# Start port-forwards in background
echo "Starting application..."
pkill -f "kubectl port-forward" 2>/dev/null
kubectl port-forward -n student-app service/backend-service 30001:3000 &
kubectl port-forward -n student-app service/frontend-service 8888:80 &
sleep 5

echo ""
echo "🏠 Frontend: http://localhost:8888"
echo "🔧 Backend API: http://localhost:30001/api"
echo ""

echo "📊 Current Data:"
curl -s http://localhost:30001/api/students | jq '.[] | "\(.name) - \(.grade) - \(.age) years"'

echo ""
echo "🎯 Demo Commands:"
echo "Add a student:"
echo 'curl -X POST http://localhost:30001/api/students \
  -H "Content-Type: application/json" \
  -d '\''{"name":"Demo Student","age":22,"grade":"A","email":"demo@school.com"}'\'''

echo ""
echo "Update a student:"
echo 'curl -X PUT http://localhost:30001/api/students/1 \
  -H "Content-Type: application/json" \
  -d '\''{"name":"Updated Name","age":23,"grade":"B","email":"updated@school.com"}'\'''

echo ""
echo "Delete a student:"
echo "curl -X DELETE http://localhost:30001/api/students/3"

echo ""
echo "⏳ The application will remain running. Use Ctrl+C to stop."
wait
