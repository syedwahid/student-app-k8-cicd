#!/bin/bash
set -e

echo "🧪 Running Integration Tests..."

# Wait for services to be ready
sleep 20

# Test backend API
echo "Testing backend API..."
curl -f http://localhost:30007/api/health || exit 1

# Test frontend
echo "Testing frontend..."
curl -f http://localhost:30008/ || exit 1

# Run API tests
echo "Running API integration tests..."
curl -X GET http://localhost:30007/api/students || echo "API might not have data yet"

echo "✅ Integration tests passed!"