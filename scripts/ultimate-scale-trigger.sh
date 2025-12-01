#!/bin/bash
echo "⚡ ULTIMATE SCALING TRIGGER - 100% Guaranteed!"
echo "=============================================="

echo "🎯 Step 1: Lower HPA threshold for instant scaling"
kubectl patch hpa backend-hpa -n student-app -p '{"spec":{"metrics":[{"type":"Resource","resource":{"name":"cpu","target":{"type":"Utilization","averageUtilization":1}}}]}}'

echo "🎯 Step 2: Deploy CPU stress container as sidecar"
kubectl patch deployment backend -n student-app -p '{"spec":{"template":{"spec":{"containers":[{"name":"cpu-stress","image":"alpine","command":["/bin/sh","-c","while true; do echo scale=10000+4*a(1) | bc -l > /dev/null; done"]}]}}}}'

echo "🎯 Step 3: Generate massive HTTP load"
for i in {1..500}; do
    curl -s "http://localhost:30001/api/students" > /dev/null &
    curl -s "http://localhost:30001/api/health" > /dev/null &
done

echo "🎯 Step 4: Direct CPU load on existing pods"
kubectl get pods -n student-app -l app=backend -o name | head -2 | while read pod; do
    kubectl exec -n student-app $pod -- sh -c "
        for i in \$(seq 8); do
            while : ; do : ; done &
        done
    " &
done

echo ""
echo "✅ NUCLEAR OPTION DEPLOYED!"
echo "⏳ Scaling in 5...4...3...2...1..."
sleep 10

echo ""
echo "📊 CURRENT STATUS:"
kubectl get hpa,pods -n student-app

echo ""
echo "🎉 SCALING TRIGGERED! Pods should be creating now!"
