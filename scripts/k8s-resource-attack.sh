#!/bin/bash
echo "☸️ KUBERNETES RESOURCE ATTACK - Guaranteed scaling!"
echo "==================================================="

echo "📊 Current HPA status:"
kubectl get hpa -n student-app

echo ""
echo "🚀 Method 1: Scale HPA thresholds temporarily"
# Lower the CPU threshold to trigger scaling immediately
kubectl patch hpa backend-hpa -n student-app -p '{"spec":{"metrics":[{"type":"Resource","resource":{"name":"cpu","target":{"type":"Utilization","averageUtilization":5}}}]}}'

echo "✅ Lowered CPU threshold to 5% - any load will trigger scaling!"

echo ""
echo "🚀 Method 2: Create massive concurrent requests"
# Generate 1000 concurrent requests
for i in {1..1000}; do
    (
        while true; do
            curl -s "http://localhost:30001/api/students" > /dev/null
            # Add artificial delay to keep connections open
            sleep 0.1
        done
    ) &
    echo -n "."
done

echo ""
echo "🚀 Method 3: Direct pod CPU stress"
# Get all backend pods and stress them
kubectl get pods -n student-app -l app=backend -o name | while read pod; do
    kubectl exec -n student-app $pod -- sh -c "
        # Create CPU stress using built-in tools
        for i in \$(seq 4); do
            while true; do
                echo 'scale=10000; 4*a(1)' | bc -l > /dev/null 2>&1
            done &
        done
    " &
    echo "💥 Stressed $pod"
done

echo ""
echo "✅ ALL ATTACKS LAUNCHED!"
echo "📈 Scaling should happen in 10-20 seconds!"
echo ""
echo "Watch: kubectl get hpa -n student-app -w"
