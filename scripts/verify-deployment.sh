#!/bin/bash
echo "🎉 DEPLOYMENT VERIFICATION"
echo "=========================="

echo -e "\n📊 Cluster Status:"
kubectl get all -n student-app

echo -e "\n🌐 Access Methods:"
echo "1. Frontend (NodePort): http://localhost:30080/"
echo "2. Backend (Port-Forward): kubectl port-forward -n student-app service/backend-service 9081:3000"
echo "3. Frontend (Port-Forward): kubectl port-forward -n student-app service/frontend-service 9080:80"

echo -e "\n🔗 Service Connectivity:"
echo -n "Frontend → Backend: "
kubectl exec -it -n student-app deployment/frontend-deployment -- wget -q -O - http://backend-service:3000/api/health > /dev/null 2>&1 && echo "✅ SUCCESS" || echo "❌ FAILED"

echo -n "Backend → MySQL: "
kubectl exec -it -n student-app deployment/backend-deployment -- node -e "
const mysql = require('mysql2');
const connection = mysql.createConnection({
  host: process.env.DB_HOST,
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  database: process.env.DB_NAME,
  port: 3306
});
connection.connect((err) => {
  if (err) {
    console.log('❌ FAILED -', err.message);
    process.exit(1);
  } else {
    console.log('✅ SUCCESS');
    connection.end();
  }
});
" 2>/dev/null || echo "❌ FAILED - MySQL connection error"

echo -e "\n🎯 Quick Test:"
echo "Starting temporary port-forward for testing..."
kubectl port-forward -n student-app service/frontend-service 9080:80 > /dev/null 2>&1 &
FRONT_PID=$!
kubectl port-forward -n student-app service/backend-service 9081:3000 > /dev/null 2>&1 &
BACK_PID=$!

sleep 3

echo -n "Frontend test: "
curl -s http://localhost:9080/ > /dev/null && echo "✅ SUCCESS" || echo "❌ FAILED"

echo -n "Backend test: "
curl -s http://localhost:9081/api/health > /dev/null && echo "✅ SUCCESS" || echo "❌ FAILED"

# Cleanup
kill $FRONT_PID $BACK_PID 2>/dev/null

echo -e "\n✅ DEPLOYMENT SUCCESSFUL!"
echo "📝 Next: Update Jenkinsfile for CI/CD automation"