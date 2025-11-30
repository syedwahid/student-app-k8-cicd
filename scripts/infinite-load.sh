#!/bin/bash
echo "♾️  INFINITE LOAD - Continuous scaling pressure!"
echo "=============================================="

echo "💥 Starting infinite load generation..."
echo "Press Ctrl+C to stop"

REQUEST_COUNT=0

while true; do
    # Generate massive concurrent load
    for i in {1..100}; do
        curl -s "http://localhost:30001/api/students?heavy=true" > /dev/null &
        curl -s "http://localhost:30001/api/health" > /dev/null &
        curl -s "http://localhost:30001/api/load-test/cpu-intensive?iterations=100000" > /dev/null &
    done
    
    REQUEST_COUNT=$((REQUEST_COUNT + 300))
    echo "📊 Total requests sent: $REQUEST_COUNT - $(date)"
    
    # Show current pod count every 10 seconds
    if (( $REQUEST_COUNT % 900 == 0 )); then
        echo "🔄 Current pod status:"
        kubectl get pods -n student-app --no-headers | wc -l | xargs echo "Active pods:"
    fi
    
    sleep 2
done
