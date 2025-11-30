#!/bin/bash
echo "🎯 DIRECT CPU ATTACK - Bypass HTTP, load pods directly!"
echo "======================================================"

echo "📊 Current pods:"
kubectl get pods -n student-app -l app=backend

echo ""
echo "💉 Injecting CPU stress directly into pods..."
# Install stress-ng in backend pods and run it
for pod in $(kubectl get pods -n student-app -l app=backend -o name); do
    echo "🔥 Stressing $pod"
    kubectl exec -n student-app $pod -- sh -c "
        apt-get update && apt-get install -y stress-ng && \
        stress-ng --cpu 4 --timeout 300s &
    " &
done

echo "🚀 Launched stress-ng on all backend pods!"
echo "⏳ Scaling should begin in 15-20 seconds!"

# Also generate HTTP load
for i in {1..100}; do
    curl -s "http://localhost:30001/api/students" > /dev/null &
done

echo "✅ Direct CPU attack running! Watch scaling happen NOW!"
