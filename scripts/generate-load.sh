#!/bin/bash
echo "🔥 Generating continuous load on backend..."
echo "Watch auto-scaling in another terminal with:"
echo "  kubectl get hpa -n student-app -w"
echo "  kubectl get pods -n student-app -w"
echo ""
echo "Press Ctrl+C to stop load generation"

# Continuous load generation
while true; do
    for i in {1..50}; do
        curl -s http://localhost:30001/api/students > /dev/null &
        curl -s http://localhost:30001/api/health > /dev/null &
    done
    sleep 1
    echo "📈 Generated 100 requests at $(date)"
done
