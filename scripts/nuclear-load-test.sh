#!/bin/bash
echo "💥 NUCLEAR LOAD TEST - Trigger scaling in 60 seconds!"
echo "===================================================="

echo "📊 Current status:"
kubectl get hpa -n student-app

echo ""
echo "🚀 Starting NUCLEAR load generation..."
echo "This will send 1000+ concurrent requests!"

# Generate massive load
for i in {1..200}; do
    echo "💣 Batch $i - Launching 500 concurrent requests..."
    
    # Fire 500 concurrent requests in background
    for j in {1..500}; do
        curl -s "http://localhost:30001/api/students?artificial_delay=100" > /dev/null &
        curl -s "http://localhost:30001/api/health" > /dev/null &
    done
    
    # Also create some students to add write load
    curl -s -X POST http://localhost:30001/api/students \
        -H "Content-Type: application/json" \
        -d '{"name":"LoadTestStudent","age":20,"grade":"A","email":"load@test.com"}' > /dev/null &
    
    echo "📈 Sent 1000+ requests in batch $i"
    sleep 1
done

echo "✅ Nuclear load complete! Watch scaling happen NOW!"
