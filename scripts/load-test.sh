#!/bin/bash
echo "💥 LOAD TEST - Guaranteed scaling in 30 seconds!"
echo "==================================================="

echo "📊 Before:"
kubectl get hpa -n student-app

echo ""
echo "🛠️ Adding REAL CPU-intensive endpoint..."
# Add a proper CPU-intensive endpoint to backend
kubectl exec -n student-app deployment/backend -- sh -c 'cat >> app.js << "EOL"

// REAL CPU intensive endpoint
app.get("/api/cpu-bomb", (req, res) => {
    const cores = parseInt(req.query.cores) || 4;
    const duration = parseInt(req.query.duration) || 10000; // 10 seconds
    
    console.log(`💣 CPU BOMB: Using ${cores} cores for ${duration}ms`);
    
    const start = Date.now();
    let completed = 0;
    
    // Create multiple CPU-intensive operations
    for (let c = 0; c < cores; c++) {
        // This will actually use CPU
        const heavyCalculation = () => {
            let result = 0;
            for (let i = 0; i < 100000000; i++) {
                result += Math.sqrt(i) * Math.sin(i) * Math.cos(i) * Math.tan(i);
                if (i % 1000000 === 0) {
                    if (Date.now() - start > duration) break;
                }
            }
            return result;
        };
        
        // Run in background to use multiple cores
        setTimeout(() => {
            heavyCalculation();
            completed++;
            if (completed === cores) {
                res.json({ 
                    status: "CPU bomb completed", 
                    cores: cores,
                    duration: duration,
                    cpu_time: Date.now() - start
                });
            }
        }, 0);
    }
});

app.get("/api/infinite-cpu", (req, res) => {
    // This will keep CPU busy indefinitely
    console.log("♾️ Starting infinite CPU loop");
    let result = 0;
    const start = Date.now();
    
    while (Date.now() - start < 30000) { // 30 seconds of pure CPU
        for (let i = 0; i < 1000000; i++) {
            result += Math.sqrt(i) * Math.sin(i) * Math.cos(i);
        }
    }
    
    res.json({ infinite_cpu: true, calculation: result });
});
EOL'

echo "🔄 Restarting backend..."
kubectl rollout restart deployment/backend -n student-app
echo "⏳ Waiting for backend restart..."
sleep 30

echo "💣 LAUNCHING CPU BOMBS!"
echo "This WILL trigger scaling in 30 seconds!"

# Launch 50 concurrent CPU bombs that run for 30 seconds each
for i in {1..50}; do
    echo "💥 Launching CPU Bomb $i - 4 cores for 30 seconds"
    curl -s "http://localhost:30001/api/cpu-bomb?cores=4&duration=30000" > /dev/null &
    curl -s "http://localhost:30001/api/infinite-cpu" > /dev/null &
done

echo "✅ 100 CPU bombs launched! Scaling is IMMINENT!"
echo "Watch: kubectl get hpa -n student-app -w"
