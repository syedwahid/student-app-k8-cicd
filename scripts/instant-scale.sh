#!/bin/bash
echo "⚡ INSTANT SCALING DEMO!"
echo "========================"

echo "📊 Initial state:"
kubectl get hpa,pods -n student-app

echo ""
echo "💥 Launching 1000 concurrent requests in background..."

# Massive concurrent load - this will definitely trigger scaling
for i in {1..1000}; do
    (
        while true; do
            curl -s "http://localhost:30001/api/students?delay=100" > /dev/null
            curl -s "http://localhost:30001/api/load-test/cpu-intensive" > /dev/null
        done
    ) &
done

echo "🚀 Load generators launched!"
echo ""
echo "📈 Watch scaling happen in real-time:"
echo "Terminal 1: kubectl get hpa -n student-app -w"
echo "Terminal 2: kubectl get pods -n student-app -w"
echo ""
echo "⏳ Scaling should begin in 20-30 seconds..."
echo ""
echo "🛑 To stop: pkill -f 'curl' && pkill -f 'instant-scale.sh'"
