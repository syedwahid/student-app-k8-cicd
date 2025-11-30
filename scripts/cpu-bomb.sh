#!/bin/bash
echo "💣 CPU BOMB - Maximizing CPU usage!"
echo "==================================="

echo "📊 Before:"
kubectl top pods -n student-app 2>/dev/null || echo "Metrics not available - will scale anyway"

echo ""
echo "💥 Detonating CPU bomb..."
echo "This creates infinite loops in the backend"

# Create CPU-intensive requests that never end
for i in {1..50}; do
    echo "🔥 Launching CPU-intensive request $i"
    
    # These requests will keep the backend busy
    curl -s "http://localhost:30001/api/students?cpu_intensive=true&loop_count=1000000" > /dev/null &
    
    # Add more concurrent requests
    for j in {1..20}; do
        curl -s "http://localhost:30001/api/students" > /dev/null &
    done
done

echo "💣 CPU Bomb active! Scaling should trigger in 30-60 seconds!"
echo "Watch: kubectl get hpa -n student-app -w"
