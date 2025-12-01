#!/bin/bash
echo "🔥 Generating CPU-intensive load..."
echo "This will trigger HPA scaling based on CPU utilization"

# Create a CPU-intensive endpoint (add this to your backend app.js temporarily)
curl -X POST http://localhost:30001/api/load-test/enable 2>/dev/null || echo "Load test endpoint not available"

# Generate CPU load
echo "Starting CPU load generation..."
for i in {1..10}; do
    echo "Batch $i - Generating CPU load..."
    for j in {1..20}; do
        # Call CPU-intensive endpoint
        curl -s "http://localhost:30001/api/students?delay=100" > /dev/null &
        curl -s "http://localhost:30001/api/load-test/cpu" > /dev/null &
    done
    sleep 2
done

echo "Load generation complete. Watch HPA scale up and then down."
