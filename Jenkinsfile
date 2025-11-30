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
        timeout(time: 15, unit: 'MINUTES')
    }
    
    stages {
        stage('Setup Lightweight Minikube') {
            steps {
                script {
                    echo "🚀 Starting lightweight Minikube (1-2 minutes)..."
                    
                    sh """
                        # Stop and clean any existing minikube
                        minikube stop 2>/dev/null || echo "No minikube to stop"
                        minikube delete 2>/dev/null || echo "No minikube to delete"
                        
                        # Start optimized lightweight minikube
                        minikube start \\
                          --driver=docker \\
                          --container-runtime=containerd \\
                          --disk-size=5gb \\
                          --cpus=1 \\
                          --memory=2g \\
                          --preload=false \\
                          --extra-config=kubelet.cgroup-driver=systemd \\
                          --force-systemd=true \\
                          --wait=all
                        
                        # Set Docker environment
                        eval \\$(minikube docker-env)
                        
                        echo "✅ Lightweight Minikube ready!"
                        minikube status
                    """
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
                        
                        # Apply all configurations
                        kubectl apply -f k8s/namespace.yaml
                        kubectl apply -f k8s/secrets.yaml
                        kubectl apply -f k8s/configmap.yaml
                        kubectl apply -f k8s/mysql/
                        kubectl apply -f k8s/backend/
                        kubectl apply -f k8s/frontend/
                        
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
                        # Wait for MySQL (most critical)
                        kubectl wait --for=condition=ready pod -l app=mysql -n ${KUBE_NAMESPACE} --timeout=180s
                        
                        # Wait for backend and frontend
                        kubectl rollout status deployment/backend -n ${KUBE_NAMESPACE} --timeout=120s
                        kubectl rollout status deployment/frontend -n ${KUBE_NAMESPACE} --timeout=120s
                        
                        echo "✅ All services ready!"
                    """
                }
            }
        }
        
        stage('Quick Smoke Test') {
            steps {
                script {
                    echo "🧪 Running quick smoke tests..."
                    
                    sh """
                        # Test backend API
                        kubectl exec -n ${KUBE_NAMESPACE} deployment/backend -- curl -s http://localhost:3000/api/health && echo "✅ Backend healthy"
                        
                        # Test frontend
                        kubectl exec -n ${KUBE_NAMESPACE} deployment/frontend -- curl -s http://localhost:80/ > /dev/null && echo "✅ Frontend healthy"
                        
                        echo "✅ Smoke tests passed!"
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
                        kubectl get pods -n ${KUBE_NAMESPACE}
                        
                        # Get service URLs
                        echo ""
                        echo "🎯 Access Your Application:"
                        echo "Frontend URL: \$(minikube service frontend-service -n ${KUBE_NAMESPACE} --url)"
                        echo ""
                        echo "💡 Quick Commands:"
                        echo "  minikube service frontend-service -n ${KUBE_NAMESPACE}"
                        echo "  kubectl get all -n ${KUBE_NAMESPACE}"
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
                    """
                }
            }
        }
    }
}