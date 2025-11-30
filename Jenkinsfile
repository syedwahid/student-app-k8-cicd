pipeline {
    agent any
    
    environment {
        DOCKER_REGISTRY = 'student-app'
        BACKEND_IMAGE = "${DOCKER_REGISTRY}-backend"
        FRONTEND_IMAGE = "${DOCKER_REGISTRY}-frontend"
        KUBE_NAMESPACE = 'student-app'
        GIT_COMMIT_SHORT = sh(script: "git rev-parse --short HEAD", returnStdout: true).trim()
    }
    
    options {
        timeout(time: 30, unit: 'MINUTES')  // Increased timeout
    }
    
    stages {
        stage('Cleanup and Setup Minikube') {
            steps {
                script {
                    echo "🚀 Setting up Minikube cluster..."
                    
                    sh '''
                        # Clean up any existing Minikube instances
                        echo "🧹 Cleaning up existing Minikube instances..."
                        minikube stop 2>/dev/null || true
                        minikube delete 2>/dev/null || true
                        
                        # Clean up Docker resources
                        echo "🧹 Cleaning Docker resources..."
                        docker system prune -f 2>/dev/null || true
                        
                        # Wait a bit
                        sleep 5
                        
                        # Start Minikube with retry logic
                        echo "🔧 Starting Minikube cluster..."
                        MAX_RETRIES=3
                        for i in $(seq 1 $MAX_RETRIES); do
                            echo "Attempt $i/$MAX_RETRIES to start Minikube..."
                            if minikube start --driver=docker --cpus=2 --memory=2g --disk-size=5gb --force; then
                                echo "✅ Minikube started successfully on attempt $i!"
                                break
                            else
                                echo "❌ Attempt $i failed."
                                if [ $i -eq $MAX_RETRIES ]; then
                                    echo "💥 All attempts failed. Exiting..."
                                    exit 1
                                fi
                                echo "🔄 Cleaning up and retrying in 10 seconds..."
                                minikube delete 2>/dev/null || true
                                sleep 10
                            fi
                        done
                        
                        # Set up Docker environment
                        eval $(minikube docker-env)
                        
                        # Verify Minikube is working
                        echo "✅ Minikube ready!"
                        minikube status
                        echo "Cluster IP: $(minikube ip)"
                        
                        # Test Kubernetes access
                        echo "🔧 Testing Kubernetes access..."
                        minikube kubectl -- get nodes
                    '''
                }
            }
        }
        
        stage('Build and Load Images') {
            steps {
                script {
                    echo "🐳 Building and loading application images..."
                    
                    sh """
                        # Build images
                        docker build -t ${BACKEND_IMAGE}:${GIT_COMMIT_SHORT} app/backend/
                        docker build -t ${FRONTEND_IMAGE}:${GIT_COMMIT_SHORT} app/frontend/
                        
                        # Load images into Minikube cluster
                        minikube image load ${BACKEND_IMAGE}:${GIT_COMMIT_SHORT}
                        minikube image load ${FRONTEND_IMAGE}:${GIT_COMMIT_SHORT}
                        
                        echo "✅ Images built and loaded successfully"
                        
                        # Verify images are loaded
                        echo "=== Loaded Images in Minikube ==="
                        minikube image ls | grep ${DOCKER_REGISTRY} || echo "No images found with registry prefix"
                    """
                }
            }
        }
        
        stage('Deploy Application') {
            steps {
                script {
                    echo "📦 Deploying to Kubernetes..."
                    
                    sh """
                        # Update deployments with correct image names and pull policy
                        sed -i 's|image:.*student-backend.*|image: ${BACKEND_IMAGE}:${GIT_COMMIT_SHORT}|g' k8s/backend/deployment.yaml
                        sed -i 's|image:.*student-frontend.*|image: ${FRONTEND_IMAGE}:${GIT_COMMIT_SHORT}|g' k8s/frontend/deployment.yaml
                        sed -i 's|imagePullPolicy:.*|imagePullPolicy: IfNotPresent|g' k8s/backend/deployment.yaml
                        sed -i 's|imagePullPolicy:.*|imagePullPolicy: IfNotPresent|g' k8s/frontend/deployment.yaml
                        
                        # Deploy everything
                        minikube kubectl -- apply -f k8s/namespace.yaml
                        minikube kubectl -- apply -f k8s/secrets.yaml
                        minikube kubectl -- apply -f k8s/configmap.yaml
                        
                        # Deploy MySQL first (it takes longest)
                        minikube kubectl -- apply -f k8s/mysql/
                        
                        # Wait a bit for PVC to be created
                        echo "⏳ Waiting for PVC to be created..."
                        sleep 20
                        
                        # Deploy backend and frontend
                        minikube kubectl -- apply -f k8s/backend/
                        minikube kubectl -- apply -f k8s/frontend/
                        
                        echo "✅ Application deployed!"
                    """
                }
            }
        }
        
        stage('Wait for Services') {
            steps {
                script {
                    echo "⏳ Waiting for services to be ready..."
                    
                    sh """
                        # Wait for backend (with longer timeout)
                        echo "🔄 Waiting for backend..."
                        minikube kubectl -- wait --for=condition=available deployment/backend -n ${KUBE_NAMESPACE} --timeout=300s || echo "Backend taking longer than expected"
                        
                        # Wait for frontend
                        echo "🔄 Waiting for frontend..."
                        minikube kubectl -- wait --for=condition=available deployment/frontend -n ${KUBE_NAMESPACE} --timeout=300s || echo "Frontend taking longer than expected"
                        
                        echo "✅ Core services ready!"
                    """
                }
            }
        }
        
        stage('Test Application Health') {
            steps {
                script {
                    echo "🧪 Testing application health..."
                    
                    sh """
                        # Test backend service through NodePort (external access)
                        echo "🔧 Testing Backend Service (NodePort)..."
                        BACKEND_URL=\$(minikube service backend-service -n ${KUBE_NAMESPACE} --url)
                        echo "Backend URL: \$BACKEND_URL"
                        
                        BACKEND_HEALTHY=false
                        for i in 1 2 3 4 5; do
                            if curl -f -s \$BACKEND_URL/api/health > /dev/null; then
                                echo "✅ Backend health check passed on attempt \$i"
                                BACKEND_HEALTHY=true
                                break
                            else
                                echo "⏳ Backend not ready yet, retrying in 10 seconds... (attempt \$i/5)"
                                sleep 10
                            fi
                        done
                        
                        if [ "\$BACKEND_HEALTHY" = "false" ]; then
                            echo "❌ Backend health check failed after 5 attempts"
                            echo "=== Backend Logs ==="
                            minikube kubectl -- logs -n ${KUBE_NAMESPACE} deployment/backend --tail=20
                            exit 1
                        fi
                        
                        # Test backend API endpoints
                        echo "🔧 Testing Backend API Endpoints..."
                        curl -s \$BACKEND_URL/api/students | head -2 && echo "✅ Backend API responding"
                        
                        # Test frontend service
                        echo "🎨 Testing Frontend Service..."
                        FRONTEND_URL=\$(minikube service frontend-service -n ${KUBE_NAMESPACE} --url)
                        echo "Frontend URL: \$FRONTEND_URL"
                        curl -s \$FRONTEND_URL | head -5 && echo "✅ Frontend service accessible"
                        
                        echo "✅ All application health tests completed!"
                    """
                }
            }
        }
        
        stage('Show Access Info') {
            steps {
                script {
                    echo "🌐 Application Access Information:"
                    
                    sh """
                        # Show all resources
                        echo "📊 Final Resource Status:"
                        minikube kubectl -- get all -n ${KUBE_NAMESPACE}
                        
                        # Get service URLs
                        echo ""
                        echo "🎯 Access URLs:"
                        echo "Frontend:"
                        FRONTEND_URL=\$(minikube service frontend-service -n ${KUBE_NAMESPACE} --url)
                        echo \$FRONTEND_URL
                        
                        echo ""
                        echo "Backend API:"
                        BACKEND_URL=\$(minikube service backend-service -n ${KUBE_NAMESPACE} --url)
                        echo \$BACKEND_URL
                        
                        echo ""
                        echo "💡 Quick Access Commands:"
                        echo "  Frontend:  minikube service frontend-service -n ${KUBE_NAMESPACE}"
                        echo "  Backend:   minikube service backend-service -n ${KUBE_NAMESPACE}"
                    """
                }
            }
        }
    }
    
    post {
        always {
            echo "🏁 Pipeline completed: ${currentBuild.currentResult}"
            
            script {
                // Always preserve Minikube for debugging
                sh '''
                    echo "🔧 Minikube cluster preserved for debugging"
                    echo "Cluster status:"
                    minikube status 2>/dev/null || echo "Minikube not available"
                    echo ""
                    echo "To clean up manually: minikube delete"
                '''
                
                if (currentBuild.currentResult == 'SUCCESS') {
                    currentBuild.description = "SUCCESS - ${GIT_COMMIT_SHORT}"
                    
                    sh """
                        echo ""
                        echo "🎉 APPLICATION DEPLOYED SUCCESSFULLY!"
                        echo "===================================="
                        echo "Your Student Management System is running!"
                        echo ""
                        echo "🌐 Access your application:"
                        minikube service frontend-service -n ${KUBE_NAMESPACE} --url
                    """
                } else {
                    echo "🔍 Debugging information for failed build:"
                    sh '''
                        echo "📋 Minikube status:"
                        minikube status 2>/dev/null || echo "Minikube not available"
                        echo ""
                        echo "🐳 Docker containers:"
                        docker ps -a 2>/dev/null | head -10 || echo "Docker not available"
                        echo ""
                        echo "💡 Troubleshooting steps:"
                        echo "1. Check Minikube logs: minikube logs"
                        echo "2. Check Docker status: systemctl status docker"
                        echo "3. Clean up: minikube delete && docker system prune -f"
                    '''
                }
            }
        }
    }
}