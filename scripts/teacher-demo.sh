#!/bin/bash
echo "🎓 TEACHER DEMO - Instant Auto-scaling"
echo "======================================"

echo "1. 🎯 SETUP MONITORING TERMINALS:"
echo "   Terminal 1: kubectl get hpa -n student-app -w"
echo "   Terminal 2: kubectl get pods -n student-app -w"
echo ""
read -p "   Press Enter when monitoring terminals are ready..."

echo ""
echo "2. 📊 INITIAL STATE:"
kubectl get hpa,deployments -n student-app

echo ""
echo "3. 💥 LAUNCHING INSTANT LOAD..."
echo "   Scaling should begin in 20-30 seconds!"

# Generate load that WILL trigger scaling
for i in {1..500}; do
    curl -s "http://localhost:30001/api/load-test/cpu-intensive?iterations=1000000" > /dev/null &
done

echo "   ✅ 500 CPU-intensive requests launched!"
echo ""
echo "4. ⏳ WAITING FOR SCALING..."
sleep 30

echo ""
echo "5. 📈 CURRENT STATE:"
kubectl get hpa,pods -n student-app

echo ""
echo "6. 🎓 TEACHING POINTS:"
echo "   • HPA detected CPU threshold breach"
echo "   • Kubernetes controller created new pods"
echo "   • Service automatically load-balances to new pods"
echo "   • Scaling happens within 30-60 seconds"
echo ""
echo "7. 👀 Continue watching terminals to see scale-down (5-15 minutes)"
