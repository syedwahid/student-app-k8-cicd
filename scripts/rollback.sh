#!/bin/bash
set -e

echo "🔄 Rolling back deployment..."

# Rollback backend
kubectl rollout undo deployment/backend-deployment -n student-app
kubectl rollout status deployment/backend-deployment -n student-app --timeout=300s

# Rollback frontend
kubectl rollout undo deployment/frontend-deployment -n student-app
kubectl rollout status deployment/frontend-deployment -n student-app --timeout=300s

echo "✅ Rollback completed!"
kubectl get pods -n student-app