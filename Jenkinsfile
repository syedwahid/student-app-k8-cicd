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
        timeout(time: 20, unit: 'MINUTES')  // Increased timeout
    }
    
    stages {
        stage('Setup Lightweight Minikube') {
            steps {
                script {
                    echo "🚀 Starting lightweight Minikube (1-2 minutes)..."
                    
                    sh '''
                        # Stop and clean any existing minikube
                        minikube stop 2>/dev/null || echo "No minikube to stop"
                        minikube delete 2>/dev/null || echo "No minikube to delete"
                        
                        # Start optimized lightweight minikube (2 CPUs minimum)
                        minikube start \
                          --driver=docker \
                          --container-runtime=containerd \
                          --disk-size=5gb \
                          --cpus=2 \
                          --memory=2g \
                          --preload=false \
                          --extra-config=kubelet.cgroup-driver=systemd \
                          --force-systemd=true \
                          --wait=all
                        
                        # Set Docker environment
                        eval $(minikube docker-env)
                        
                        echo "✅ Lightweight Minikube ready!"
                        minikube status
                    '''
                }
            }
        }
        
        stage('Build Images') {
            steps {
                script {
                    echo "🐳 Building application images..."
                    
                    sh """
                        # Build images directly in Minikube's Docker
                        docker build -t ${BACKEND_IMAGE}:${GIT_COMMIT_SHORT} app/backend/
                        docker build -t ${FRONTEND_IMAGE}:${GIT_COMMIT_SHORT} app/frontend/
                        
                        echo "✅ Images built successfully"
                        docker images | grep student
                    """
                }
            }
        }
        
        stage('Deploy Application') {
            steps {
                script {
                    echo "📦 Deploying to Kubernetes..."
                    
                    sh """
                        # Update deployments for local images
                        sed -i 's|imagePullPolicy:.*|imagePullPolicy: IfNotPresent|g' k8s/backend/deployment.yaml
                        sed -i 's|imagePullPolicy:.*|imagePullPolicy: IfNotPresent|g' k8s/frontend/deployment.yaml
                        
                        # Use minikube kubectl instead of system kubectl
                        minikube kubectl -- apply -f k8s/namespace.yaml
                        minikube kubectl -- apply -f k8s/secrets.yaml
                        minikube kubectl -- apply -f k8s/configmap.yaml
                        minikube kubectl -- apply -f k8s/mysql/
                        minikube kubectl -- apply -f k8s/backend/
                        minikube kubectl -- apply -f k8s/frontend/
                        
                        echo "✅ Application deployed!"
                    """
                }
            }
        }
        
        stage('Wait for MySQL') {
            steps {
                script {
                    echo "🗄️ Waiting for MySQL to be ready (this can take 2-5 minutes)..."
                    
                    sh """
                        # Give MySQL more time to start (5 minutes timeout)
                        minikube kubectl -- wait --for=condition=ready pod -l app=mysql -n ${KUBE_NAMESPACE} --timeout=300s || echo "MySQL taking longer than expected, continuing..."
                        
                        # Check MySQL logs if it's taking too long
                        echo "📋 MySQL pod status:"
                        minikube kubectl -- get pods -l app=mysql -n ${KUBE_NAMESPACE}
                        
                        # Show recent MySQL logs
                        echo "📄 MySQL logs (last 10 lines):"
                        minikube kubectl -- logs -l app=mysql -n ${KUBE_NAMESPACE} --tail=10 || echo "No logs available yet"
                    """
                }
            }
        }
        
        stage('Wait for Backend and Frontend') {
            steps {
                script {
                    echo "⏳ Waiting for backend and frontend services..."
                    
                    sh """
                        # Wait for backend with timeout
                        minikube kubectl -- rollout status deployment/backend -n ${KUBE_NAMESPACE} --timeout=120s || echo "Backend rollout in progress"
                        
                        # Wait for frontend with timeout  
                        minikube kubectl -- rollout status deployment/frontend -n ${KUBE_NAMESPACE} --timeout=120s || echo "Frontend rollout in progress"
                        
                        echo "✅ Core services ready!"
                    """
                }
            }
        }
        
        stage('Quick Smoke Test') {
            steps {
                script {
                    echo "🧪 Running quick smoke tests..."
                    
                    sh """
                        # Test backend API (with retry logic)
                        echo "🔧 Testing Backend API..."
                        for i in {1..5}; do
                            if minikube kubectl -- exec -n ${KUBE_NAMESPACE} deployment/backend -- curl -s http://localhost:3000/api/health > /dev/null; then
                                echo "✅ Backend health check passed"
                                break
                            else
                                echo "⏳ Backend not ready yet, retrying in 10 seconds..."
                                sleep 10
                            fi
                        done
                        
                        # Test frontend
                        echo "🎨 Testing Frontend..."
                        minikube kubectl -- exec -n ${KUBE_NAMESPACE} deployment/frontend -- curl -s http://localhost:80/ > /dev/null && echo "✅ Frontend healthy"
                        
                        echo "✅ Smoke tests completed!"
                    """
                }
            }
        }
        
        stage('Show Access Info') {
            steps {
                script {
                    echo "🌐 Application Access Information:"
                    
                    sh """
                        # Show cluster info
                        echo "📊 Cluster Status:"
                        minikube kubectl -- get pods -n ${KUBE_NAMESPACE}
                        
                        # Get service URLs
                        echo ""
                        echo "🎯 Access Your Application:"
                        echo "Frontend URL:"
                        minikube service frontend-service -n ${KUBE_NAMESPACE} --url || echo "Use: minikube service frontend-service -n student-app"
                        echo ""
                        echo "Backend API:"
                        minikube service backend-service -n ${KUBE_NAMESPACE} --url || echo "Use: minikube service backend-service -n student-app"
                        echo ""
                        echo "💡 Quick Commands:"
                        echo "  Frontend: minikube service frontend-service -n ${KUBE_NAMESPACE}"
                        echo "  Backend:  minikube service backend-service -n ${KUBE_NAMESPACE}"
                        echo "  Status:   minikube kubectl -- get all -n ${KUBE_NAMESPACE}"
                    """
                }
            }
        }
    }
    
    post {
        always {
            echo "🏁 Pipeline completed: ${currentBuild.currentResult}"
            
            script {
                if (currentBuild.currentResult == 'SUCCESS') {
                    currentBuild.description = "SUCCESS - ${GIT_COMMIT_SHORT}"
                    
                    sh """
                        echo ""
                        echo "🎉 DEPLOYMENT SUCCESSFUL!"
                        echo "========================"
                        echo "Access your Student Management App:"
                        minikube service frontend-service -n ${KUBE_NAMESPACE} --url
                        echo ""
                        echo "📊 Final Status:"
                        minikube kubectl -- get all -n ${KUBE_NAMESPACE}
                    """
                } else {
                    echo "❌ Deployment had issues. Check MySQL initialization."
                    sh """
                        echo "🔍 Debug Information:"
                        minikube kubectl -- get pods -n ${KUBE_NAMESPACE}
                        echo ""
                        echo "📄 MySQL logs:"
                        minikube kubectl -- logs -l app=mysql -n ${KUBE_NAMESPACE} --tail=20 || echo "No MySQL logs"
                        echo ""
                        echo "📄 Backend logs:"
                        minikube kubectl -- logs -l app=backend -n ${KUBE_NAMESPACE} --tail=10 || echo "No backend logs"
                    """
                }
            }
        }
    }
}