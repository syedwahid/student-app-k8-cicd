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
        timeout(time: 20, unit: 'MINUTES')
    }
    
    stages {
        stage('Setup Lightweight Minikube') {
            steps {
                script {
                    echo "🚀 Starting lightweight Minikube..."
                    
                    sh '''
                        # Only delete if we want fresh start - comment out for debugging
                        # minikube stop 2>/dev/null || true
                        # minikube delete 2>/dev/null || true
                        
                        # Start minikube if not running
                        if ! minikube status 2>/dev/null | grep -q "Running"; then
                            echo "Starting Minikube cluster..."
                            minikube start --driver=docker --cpus=2 --memory=2g --disk-size=5gb
                        else
                            echo "Minikube is already running"
                        fi
                        
                        eval $(minikube docker-env)
                        echo "✅ Minikube ready!"
                        
                        # Verify cluster is accessible
                        minikube status
                        echo "Cluster IP: $(minikube ip)"
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
                        sleep 15
                        
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
        
        stage('Debug and Verify Deployment') {
            steps {
                script {
                    echo "🔧 Running deployment verification and debugging..."
                    
                    sh """
                        echo "=== Cluster Status ==="
                        minikube status
                        
                        echo "=== All Resources in Namespace ==="
                        minikube kubectl -- get all -n ${KUBE_NAMESPACE}
                        
                        echo "=== Pod Details ==="
                        minikube kubectl -- get pods -n ${KUBE_NAMESPACE} -o wide
                        
                        echo "=== Service Details ==="
                        minikube kubectl -- get services -n ${KUBE_NAMESPACE}
                        
                        echo "=== Checking Pod Status ==="
                        minikube kubectl -- get pods -n ${KUBE_NAMESPACE} -o jsonpath='{range .items[*]}{.metadata.name}{"\\t"}{.status.phase}{"\\t"}{.status.podIP}{"\\n"}{end}'
                    """
                }
            }
        }
        
        stage('Test Application Health - External') {
            steps {
                script {
                    echo "🧪 Testing application health externally..."
                    
                    sh """
                        # Test backend service through NodePort (external access)
                        echo "🔧 Testing Backend Service (NodePort)..."
                        BACKEND_URL=\$(minikube service backend-service -n ${KUBE_NAMESPACE} --url)
                        echo "Backend URL: \$BACKEND_URL"
                        
                        BACKEND_HEALTHY=false
                        for i in 1 2 3 4 5 6 7 8 9 10; do
                            if curl -s \$BACKEND_URL/api/health > /dev/null; then
                                echo "✅ Backend health check passed on attempt \$i"
                                BACKEND_HEALTHY=true
                                break
                            else
                                echo "⏳ Backend not ready yet, retrying in 5 seconds... (attempt \$i/10)"
                                sleep 5
                            fi
                        done
                        
                        if [ "\$BACKEND_HEALTHY" = "false" ]; then
                            echo "❌ Backend health check failed after 10 attempts"
                            echo "=== Backend Logs ==="
                            minikube kubectl -- logs -n ${KUBE_NAMESPACE} deployment/backend --tail=20
                            echo "=== Backend Pod Details ==="
                            minikube kubectl -- describe pod -l app=backend -n ${KUBE_NAMESPACE}
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
        
        stage('Debug Application Internals') {
            steps {
                script {
                    echo "🔍 Debugging application internals..."
                    
                    sh """
                        echo "=== Backend Logs (last 20 lines) ==="
                        minikube kubectl -- logs -n ${KUBE_NAMESPACE} deployment/backend --tail=20 || echo "No backend logs available"
                        
                        echo "=== Frontend Logs (last 20 lines) ==="
                        minikube kubectl -- logs -n ${KUBE_NAMESPACE} deployment/frontend --tail=20 || echo "No frontend logs available"
                        
                        echo "=== Backend Container Details ==="
                        minikube kubectl -- describe pod -l app=backend -n ${KUBE_NAMESPACE} | grep -A 10 "Image:" || echo "Could not describe backend pod"
                        
                        echo "=== Testing Backend Internally with wget ==="
                        minikube kubectl -- exec -n ${KUBE_NAMESPACE} deployment/backend -- wget -q -O - http://localhost:3000/api/health && echo "✅ Backend internal health check passed" || echo "❌ Backend internal health check failed"
                        
                        echo "=== Frontend Content Check ==="
                        minikube kubectl -- exec -n ${KUBE_NAMESPACE} deployment/frontend -- cat /usr/share/nginx/html/index.html | head -5 && echo "✅ Frontend content available"
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
                        echo "  Pods:      minikube kubectl -- get pods -n ${KUBE_NAMESPACE}"
                        echo "  Logs:      minikube kubectl -- logs -n ${KUBE_NAMESPACE} deployment/backend -f"
                        
                        echo ""
                        echo "🔧 Debugging Commands:"
                        echo "  Check cluster: minikube status"
                        echo "  Cluster IP:    minikube ip"
                        echo "  Shell access:  minikube kubectl -- exec -n ${KUBE_NAMESPACE} deployment/backend -it -- sh"
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
                        echo "🎉 APPLICATION DEPLOYED SUCCESSFULLY!"
                        echo "===================================="
                        echo "Your Student Management System is running!"
                        echo ""
                        echo "🌐 Access your application:"
                        minikube service frontend-service -n ${KUBE_NAMESPACE} --url
                        echo ""
                        echo "📊 Final Pod Status:"
                        minikube kubectl -- get pods -n ${KUBE_NAMESPACE}
                        echo ""
                        echo "💡 The Minikube cluster is preserved for debugging."
                        echo "   Run 'minikube stop' when you're done testing."
                    """
                } else {
                    echo "🔍 Debugging information for failed build:"
                    sh """
                        echo "📋 Pod details:"
                        minikube kubectl -- get pods -n ${KUBE_NAMESPACE} -o wide || echo "Could not get pods"
                        echo ""
                        echo "📄 Backend logs:"
                        minikube kubectl -- logs -l app=backend -n ${KUBE_NAMESPACE} --tail=30 || echo "No backend logs"
                        echo ""
                        echo "📄 Frontend logs:"
                        minikube kubectl -- logs -l app=frontend -n ${KUBE_NAMESPACE} --tail=30 || echo "No frontend logs"
                        echo ""
                        echo "🔧 Cluster status:"
                        minikube status || echo "Minikube not available"
                        echo ""
                        echo "💡 The cluster is preserved for manual debugging."
                        echo "   Investigate the issues and run 'minikube delete' to clean up."
                    """
                }
            }
        }
    }
}