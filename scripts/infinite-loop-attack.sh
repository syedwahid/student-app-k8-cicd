#!/bin/bash
echo "♾️ INFINITE LOOP ATTACK - Maximum CPU usage!"
echo "==========================================="

echo "🛠️ Adding infinite loop endpoint..."
kubectl exec -n student-app deployment/backend -- sh -c 'cat >> app.js << "EOL"

app.get("/api/infinite-loop", (req, res) => {
    console.log("🔥 Starting infinite CPU loop");
    const startTime = Date.now();
    let iterations = 0;
    
    // This will use 100% CPU until timeout
    while (true) {
        iterations++;
        // Heavy math operations
        for (let i = 0; i < 100000; i++) {
            Math.sqrt(i) * Math.sin(i) * Math.cos(i) * Math.tan(i);
        }
        
        // Break after 2 minutes to avoid permanent damage
        if (Date.now() - startTime > 120000) {
            break;
        }
    }
    
    res.json({ 
        status: "Infinite loop completed", 
        iterations: iterations,
        duration: Date.now() - startTime 
    });
});

app.get("/api/max-cpu", (req, res) => {
    const threadCount = parseInt(req.query.threads) || 8;
    console.log(`🚀 Starting ${threadCount} CPU threads`);
    
    let completed = 0;
    const results = [];
    
    for (let t = 0; t < threadCount; t++) {
        setTimeout(() => {
            let result = 0;
            for (let i = 0; i < 50000000; i++) {
                result += Math.sqrt(i) * Math.sin(i) * Math.cos(i);
            }
            results.push(result);
            completed++;
            
            if (completed === threadCount) {
                res.json({ 
                    threads: threadCount,
                    results: results.length 
                });
            }
        }, 0);
    }
});
EOL'

echo "🔄 Restarting backend..."
kubectl rollout restart deployment/backend -n student-app
sleep 30

echo "💥 LAUNCHING INFINITE LOOPS!"
# Launch infinite loops that will use 100% CPU
for i in {1..20}; do
    echo "🔥 Starting infinite loop $i"
    curl -s "http://localhost:30001/api/infinite-loop" > /dev/null &
    curl -s "http://localhost:30001/api/max-cpu?threads=8" > /dev/null &
done

echo "✅ 40 infinite loops launched! CPU at 100%!"
echo "Scaling WILL happen in 15-30 seconds!"
