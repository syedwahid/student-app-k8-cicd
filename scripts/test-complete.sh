#!/bin/bash
echo "🎯 Complete Application Test"

echo "1. Checking pod status..."
kubectl get pods -n student-app

echo -e "\n2. Testing backend internally..."
# Test if backend process is running
kubectl exec -it -n student-app deployment/backend-deployment -- ps aux | grep node

# Test backend with Node.js
kubectl exec -it -n student-app deployment/backend-deployment -- node -e "
const http = require('http');
const req = http.request('http://localhost:3000/api/health', { method: 'GET' }, (res) => {
  let data = '';
  res.on('data', chunk => data += chunk);
  res.on('end', () => {
    console.log('Backend Health Check:');
    console.log('Status:', res.statusCode);
    console.log('Response:', data);
  });
});
req.on('error', (err) => console.log('Backend Error:', err.message));
req.end();
"

echo -e "\n3. Testing frontend internally..."
kubectl exec -it -n student-app deployment/frontend-deployment -- wget -q -O - http://localhost:80/ | head -n 5

echo -e "\n4. Testing service connectivity..."
kubectl exec -it -n student-app deployment/frontend-deployment -- nslookup backend-service

echo -e "\n5. Testing via port-forward..."
pkill -f "kubectl port-forward" 2>/dev/null || true

echo "Starting port-forward for backend..."
kubectl port-forward -n student-app service/backend-service 9081:3000 > /dev/null 2>&1 &
BACKEND_PF_PID=$!

echo "Starting port-forward for frontend..."
kubectl port-forward -n student-app service/frontend-service 9080:80 > /dev/null 2>&1 &
FRONTEND_PF_PID=$!

sleep 3

echo "Testing backend via port-forward..."
curl -s http://localhost:9081/api/health || echo "Backend not accessible"

echo "Testing frontend via port-forward..."
curl -s http://localhost:9080/ | head -n 5 || echo "Frontend not accessible"

# Cleanup
kill $BACKEND_PF_PID 2>/dev/null || true
kill $FRONTEND_PF_PID 2>/dev/null || true

echo -e "\n✅ Test completed"