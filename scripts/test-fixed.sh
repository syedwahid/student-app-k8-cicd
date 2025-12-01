#!/bin/bash
echo "🔧 Fixed Application Test"

echo "1. Checking pod readiness..."
kubectl get pods -n student-app -l app=backend

echo -e "\n2. Testing backend with IPv4..."
kubectl exec -it -n student-app deployment/backend-deployment -- node -e "
const http = require('http');
const req = http.request('http://127.0.0.1:3000/api/health', { method: 'GET' }, (res) => {
  let data = '';
  res.on('data', chunk => data += chunk);
  res.on('end', () => {
    console.log('✅ Backend Health Check (IPv4):');
    console.log('Status:', res.statusCode);
    console.log('Response:', data);
  });
});
req.on('error', (err) => console.log('❌ Backend Error:', err.message));
req.end();
"

echo -e "\n3. Testing service discovery..."
kubectl exec -it -n student-app deployment/frontend-deployment -- wget -q -O - http://backend-service.student-app.svc.cluster.local:3000/api/health && echo "✅ Frontend to Backend connection: SUCCESS" || echo "❌ Frontend to Backend connection: FAILED"

echo -e "\n4. Testing via NodePort..."
echo "Backend NodePort test:"
curl -s http://localhost:30007/api/health && echo "✅ Backend NodePort: SUCCESS" || echo "❌ Backend NodePort: FAILED"

echo "Frontend NodePort test:"
curl -s http://localhost:30080/ | head -n 3 && echo "✅ Frontend NodePort: SUCCESS" || echo "❌ Frontend NodePort: FAILED"

echo -e "\n5. Final status:"
kubectl get all -n student-app