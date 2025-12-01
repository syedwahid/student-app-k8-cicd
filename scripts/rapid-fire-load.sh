#!/bin/bash
echo "🔫 RAPID FIRE LOAD - Scaling in 30 seconds!"
echo "==========================================="

# First, let's add a CPU-intensive endpoint to backend
echo "🛠️  Enhancing backend for better load testing..."
kubectl exec -n student-app deployment/backend -- sh -c 'cat >> app.js << "EOL"

// CPU intensive endpoint for load testing
app.get("/api/load-test/cpu-intensive", (req, res) => {
    const iterations = parseInt(req.query.iterations) || 1000000;
    let result = 0;
    
    console.log(`🚀 Starting CPU intensive work: ${iterations} iterations`);
    
    // Heavy CPU work
    for (let i = 0; i < iterations; i++) {
        result += Math.sqrt(i) * Math.sin(i) * Math.cos(i);
    }
    
    res.json({ 
        status: "CPU work completed", 
        iterations: iterations,
        result: result 
    });
});

app.get("/api/students/slow", (req, res) => {
    const delay = parseInt(req.query.delay) || 500; // 500ms default delay
    const start = Date.now();
    
    // Simulate slow database query
    setTimeout(() => {
        const end = Date.now();
        res.json({
            students: students,
            processing_time: end - start,
            delayed: delay
        });
    }, delay);
});
EOL'

echo "🔄 Restarting backend to load new endpoints..."
kubectl rollout restart deployment/backend -n student-app

echo "⏳ Waiting for backend to restart..."
sleep 30

echo "💥 STARTING RAPID FIRE ATTACK!"
echo "This will trigger scaling within 30 seconds!"

# Generate massive concurrent load
for i in {1..10}; do
    echo "🔫 Round $i - Firing 200 concurrent CPU-intensive requests..."
    
    # Fire 200 CPU-intensive requests
    for j in {1..200}; do
        curl -s "http://localhost:30001/api/load-test/cpu-intensive?iterations=500000" > /dev/null &
        curl -s "http://localhost:30001/api/students/slow?delay=200" > /dev/null &
    done
    
    echo "📈 Sent 400 heavy requests in round $i"
    sleep 3
done

echo "✅ Rapid fire complete! Scaling should be happening NOW!"
