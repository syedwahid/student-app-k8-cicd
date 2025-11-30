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
                        minikube stop 2>/dev/null || true
                        minikube delete 2>/dev/null || true
                        minikube start --driver=docker --cpus=2 --memory=2g --disk-size=5gb
                        eval $(minikube docker-env)
                        echo "✅ Minikube ready!"
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
                        sleep 10
                        
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
        
        stage('Test Application') {
            steps {
                script {
                    echo "🧪 Testing application..."
                    
                    sh """
                        # Test backend API with retries
                        echo "🔧 Testing Backend API..."
                        for i in {1..10}; do
                            if minikube kubectl -- exec -n ${KUBE_NAMESPACE} deployment/backend -- curl -s http://localhost:3000/api/health > /dev/null; then
                                echo "✅ Backend health check passed"
                                break
                            else
                                echo "⏳ Backend not ready yet, retrying in 10 seconds... (attempt $i/10)"
                                sleep 10
                            fi
                        done
                        
                        # Test frontend
                        echo "🎨 Testing Frontend..."
                        minikube kubectl -- exec -n ${KUBE_NAMESPACE} deployment/frontend -- curl -s http://localhost:80/ > /dev/null && echo "✅ Frontend healthy"
                        
                        echo "✅ Application tests completed!"
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
                        echo "📊 All Resources:"
                        minikube kubectl -- get all -n ${KUBE_NAMESPACE}
                        
                        # Get service URLs
                        echo ""
                        echo "🎯 Access URLs:"
                        echo "Frontend:"
                        minikube service frontend-service -n ${KUBE_NAMESPACE} --url
                        echo ""
                        echo "Backend API:"
                        minikube service backend-service -n ${KUBE_NAMESPACE} --url
                        echo ""
                        echo "💡 Quick Access:"
                        echo "  minikube service frontend-service -n ${KUBE_NAMESPACE}"
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
                        echo "📊 Final Status:"
                        minikube kubectl -- get pods -n ${KUBE_NAMESPACE}
                    """
                } else {
                    echo "🔍 Debugging information:"
                    sh """
                        echo "📋 Pod details:"
                        minikube kubectl -- get pods -n ${KUBE_NAMESPACE} -o wide
                        echo ""
                        echo "📄 Backend logs:"
                        minikube kubectl -- logs -l app=backend -n ${KUBE_NAMESPACE} --tail=20 || echo "No backend logs"
                        echo ""
                        echo "📄 Frontend logs:"
                        minikube kubectl -- logs -l app=frontend -n ${KUBE_NAMESPACE} --tail=20 || echo "No frontend logs"
                        echo ""
                        echo "💡 Try accessing the application anyway:"
                        minikube service frontend-service -n ${KUBE_NAMESPACE} --url || echo "minikube service frontend-service -n student-app"
                    """
                }
            }
        }
    }
}