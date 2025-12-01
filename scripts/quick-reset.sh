#!/bin/bash
echo "🔄 Quick Reset - Student Management App"
echo "======================================"

# Stop everything
echo "🧹 Cleaning up..."
./scripts/teardown.sh
pkill -f "kubectl port-forward" 2>/dev/null || true

# Wait for cleanup
sleep 10

# Rebuild and redeploy
echo "🚀 Redeploying..."
./scripts/deploy.sh

# Wait a bit
sleep 20

# Start access
echo "🌐 Starting access..."
./scripts/access-app.sh
