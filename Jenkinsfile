pipeline {
    agent any
    
    environment {
        // Docker Hub Configuration
        DOCKER_REGISTRY = 'syedwahid'  // CHANGE THIS
        BACKEND_IMAGE = "${DOCKER_REGISTRY}/student-backend"
        FRONTEND_IMAGE = "${DOCKER_REGISTRY}/student-frontend"
        
        // Minikube Configuration
        KUBE_NAMESPACE = 'student-app'
        MINIKUBE_PROFILE = 'student-app-cicd'
        
        // Git Information
        GIT_COMMIT_SHORT = sh(script: "git rev-parse --short HEAD", returnStdout: true).trim()
        GIT_BRANCH = sh(script: "git rev-parse --abbrev-ref HEAD", returnStdout: true).trim()
    }
    
    options {
        timeout(time: 30, unit: 'MINUTES')
        disableConcurrentBuilds()
    }
    
    stages {
        stage('Pre-Build Setup') {
            steps {
                script {
                    echo "🚀 Starting CI/CD Pipeline with Minikube"
                    echo "📝 Build Number: ${env.BUILD_NUMBER}"
                    echo "🔖 Git Commit: ${env.GIT_COMMIT_SHORT}"
                    echo "🌿 Git Branch: ${env.GIT_BRANCH}"
                    
                    // Check if required tools are available
                    sh '''
                        echo "🔧 Checking required tools..."
                        
                        # Check Minikube
                        if command -v minikube >/dev/null 2>&1; then
                            echo "✅ Minikube is available"
                            minikube version
                        else
                            echo "❌ Minikube is not available"
                            exit 1
                        fi
                        
                        # Check Docker
                        if command -v docker >/dev/null 2>&1; then
                            echo "✅ Docker is available"
                            docker --version
                        else
                            echo "❌ Docker is not available"
                            exit 1
                        fi
                    '''
                }
            }
        }
        
        stage('Start Minikube') {
            steps {
                script {
                    echo "🔧 Starting Minikube..."
                    
                    sh """
                        # Check if Minikube is running
                        if minikube status --profile=${MINIKUBE_PROFILE} | grep -q "Running"; then
                            echo "✅ Minikube is already running"
                        else
                            echo "🚀 Starting Minikube..."
                            minikube start --profile=${MINIKUBE_PROFILE} --driver=docker --cpus=2 --memory=4000mb --disk-size=20gb
                        fi
                        
                        # Set Minikube docker env
                        echo "🐳 Configuring Docker to use Minikube's daemon..."
                        eval \$(minikube docker-env --profile=${MINIKUBE_PROFILE})
                        
                        echo "✅ Minikube setup completed"
                    """
                }
            }
        }
        
        stage('Build Docker Images') {
            steps {
                script {
                    echo "🐳 Building Docker Images in Minikube environment..."
                    
                    // Build Backend Image
                    sh "docker build -t ${BACKEND_IMAGE}:${GIT_COMMIT_SHORT} app/backend"
                    sh "docker build -t ${BACKEND_IMAGE}:latest app/backend"
                    
                    // Build Frontend Image  
                    sh "docker build -t ${FRONTEND_IMAGE}:${GIT_COMMIT_SHORT} app/frontend"
                    sh "docker build -t ${FRONTEND_IMAGE}:latest app/frontend"
                    
                    echo "✅ Docker images built successfully"
                    
                    // List images to verify
                    sh "docker images | grep student-"
                }
            }
        }
        
        stage('Deploy to Minikube') {
            steps {
                script {
                    echo "🚀 Deploying to Minikube Kubernetes..."
                    
                    // Update Kubernetes manifests
                    sh """
                        echo "🔄 Updating Kubernetes manifests..."
                        
                        # Use local images and set imagePullPolicy to Never
                        sed -i 's|image:.*student-backend.*|image: ${BACKEND_IMAGE}:${GIT_COMMIT_SHORT}|g' k8s/backend/deployment.yaml
                        sed -i 's|image:.*student-frontend.*|image: ${FRONTEND_IMAGE}:${GIT_COMMIT_SHORT}|g' k8s/frontend/deployment.yaml
                        sed -i 's|imagePullPolicy:.*|imagePullPolicy: Never|g' k8s/backend/deployment.yaml
                        sed -i 's|imagePullPolicy:.*|imagePullPolicy: Never|g' k8s/frontend/deployment.yaml
                        
                        echo "✅ Manifests updated"
                    """
                    
                    // Apply Kubernetes configurations
                    sh """
                        echo "📋 Applying Kubernetes configurations..."
                        
                        # Create namespace
                        minikube kubectl --profile=${MINIKUBE_PROFILE} -- apply -f k8s/namespace.yaml --validate=false
                        
                        # Apply secrets and configmaps
                        minikube kubectl --profile=${MINIKUBE_PROFILE} -- apply -f k8s/secrets.yaml --validate=false
                        minikube kubectl --profile=${MINIKUBE_PROFILE} -- apply -f k8s/configmap.yaml --validate=false
                        
                        # Deploy MySQL
                        minikube kubectl --profile=${MINIKUBE_PROFILE} -- apply -f k8s/mysql/ --validate=false
                        
                        # Wait for MySQL to be ready
                        echo "⏳ Waiting for MySQL to be ready..."
                        minikube kubectl --profile=${MINIKUBE_PROFILE} -- wait --for=condition=ready pod -l app=mysql -n ${KUBE_NAMESPACE} --timeout=300s
                        
                        # Deploy backend and frontend
                        minikube kubectl --profile=${MINIKUBE_PROFILE} -- apply -f k8s/backend/ --validate=false
                        minikube kubectl --profile=${MINIKUBE_PROFILE} -- apply -f k8s/frontend/ --validate=false
                        
                        echo "✅ Kubernetes deployment completed"
                    """
                    
                    // Wait for deployments to be ready
                    sh """
                        echo "⏳ Waiting for deployments to be ready..."
                        minikube kubectl --profile=${MINIKUBE_PROFILE} -- rollout status deployment/backend -n ${KUBE_NAMESPACE} --timeout=300s
                        minikube kubectl --profile=${MINIKUBE_PROFILE} -- rollout status deployment/frontend -n ${KUBE_NAMESPACE} --timeout=300s
                    """
                }
            }
        }
        
        stage('Smoke Tests') {
            steps {
                script {
                    echo "🧪 Running Smoke Tests..."
                    
                    // Wait for services to be ready
                    sleep 30
                    
                    // Test backend health
                    sh """
                        echo "🔧 Testing Backend API..."
                        if minikube kubectl --profile=${MINIKUBE_PROFILE} -- exec -n ${KUBE_NAMESPACE} deployment/backend -- curl -s http://localhost:3000/api/health > /dev/null; then
                            echo "✅ Backend health check passed"
                        else
                            echo "❌ Backend health check failed"
                            exit 1
                        fi
                    """
                    
                    echo "✅ All smoke tests passed!"
                }
            }
        }
        
        stage('Show Application URLs') {
            steps {
                script {
                    echo "🌐 Application Access URLs:"
                    
                    sh """
                        # Get frontend service URL
                        echo "🎨 Frontend URL:"
                        minikube service --profile=${MINIKUBE_PROFILE} --url frontend-service -n ${KUBE_NAMESPACE} || echo "Frontend service not available"
                    """
                }
            }
        }
    }
    
    post {
        always {
            echo "📊 Build completed with status: ${currentBuild.currentResult}"
        }
        success {
            script {
                echo "🎉 Pipeline executed successfully!"
                currentBuild.description = "SUCCESS - ${GIT_COMMIT_SHORT}"
            }
        }
        failure {
            script {
                echo "💥 Pipeline failed!"
                currentBuild.description = "FAILED - ${GIT_COMMIT_SHORT}"
                
                // Simple cleanup instead of complex rollback
                sh """
                    echo "🧹 Cleaning up failed deployment..."
                    minikube kubectl --profile=${MINIKUBE_PROFILE} -- delete -f k8s/backend/ --ignore-not-found=true || true
                    minikube kubectl --profile=${MINIKUBE_PROFILE} -- delete -f k8s/frontend/ --ignore-not-found=true || true
                """
            }
        }
    }
}