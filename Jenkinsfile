pipeline {
    agent any
    
    environment {
        // Docker Hub Configuration
        DOCKERHUB_CREDENTIALS = credentials('docker-hub')
        DOCKER_REGISTRY = 'your-dockerhub-username'
        BACKEND_IMAGE = "${DOCKER_REGISTRY}/student-backend"
        FRONTEND_IMAGE = "${DOCKER_REGISTRY}/student-frontend"
        
        // Minikube Configuration
        KUBE_NAMESPACE = 'student-app'
        MINIKUBE_PROFILE = 'student-app-cicd'
        
        // Git Information
        GIT_COMMIT = sh(script: "git rev-parse HEAD", returnStdout: true).trim()
        GIT_COMMIT_SHORT = sh(script: "git rev-parse --short HEAD", returnStdout: true).trim()
        GIT_BRANCH = sh(script: "git rev-parse --abbrev-ref HEAD", returnStdout: true).trim()
        
        // Build Information
        BUILD_TIMESTAMP = sh(script: "date -u +'%Y-%m-%dT%H:%M:%SZ'", returnStdout: true).trim()
        BUILD_VERSION = "${env.BUILD_NUMBER}-${GIT_COMMIT_SHORT}"
    }
    
    options {
        buildDiscarder(logRotator(numToKeepStr: '10'))
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
        
        stage('Checkout Code') {
            steps {
                checkout scm
                
                script {
                    currentBuild.displayName = "#${BUILD_NUMBER}-${GIT_COMMIT_SHORT}"
                    currentBuild.description = "Branch: ${env.GIT_BRANCH}"
                }
            }
        }
        
        stage('Build Docker Images in Minikube') {
            steps {
                script {
                    echo "🐳 Building Docker Images in Minikube environment..."
                    
                    // Set Docker to use Minikube's daemon
                    sh "eval \$(minikube docker-env --profile=${MINIKUBE_PROFILE})"
                    
                    // Build Backend Image
                    sh "docker build -t ${BACKEND_IMAGE}:${GIT_COMMIT_SHORT} app/backend"
                    sh "docker build -t ${BACKEND_IMAGE}:latest app/backend"
                    
                    // Build Frontend Image  
                    sh "docker build -t ${FRONTEND_IMAGE}:${GIT_COMMIT_SHORT} app/frontend"
                    sh "docker build -t ${FRONTEND_IMAGE}:latest app/frontend"
                    
                    echo "✅ Docker images built in Minikube environment"
                    
                    // List images to verify
                    sh "docker images | grep student-"
                }
            }
        }
        
        stage('Deploy to Minikube') {
            steps {
                script {
                    echo "🚀 Deploying to Minikube Kubernetes..."
                    
                    // Update Kubernetes manifests to use local images (no need to push to Docker Hub)
                    sh """
                        echo "🔄 Updating Kubernetes manifests..."
                        
                        # Use local images (built in Minikube)
                        sed -i 's|${BACKEND_IMAGE}:latest|${BACKEND_IMAGE}:${GIT_COMMIT_SHORT}|g' k8s/backend/deployment.yaml
                        sed -i 's|${FRONTEND_IMAGE}:latest|${FRONTEND_IMAGE}:${GIT_COMMIT_SHORT}|g' k8s/frontend/deployment.yaml
                        
                        # Set imagePullPolicy to Never for local images
                        sed -i 's|imagePullPolicy: Always|imagePullPolicy: Never|g' k8s/backend/deployment.yaml
                        sed -i 's|imagePullPolicy: Always|imagePullPolicy: Never|g' k8s/frontend/deployment.yaml
                        
                        # Update build annotations
                        sed -i 's|{{BUILD_TIMESTAMP}}|${BUILD_TIMESTAMP}|g' k8s/backend/deployment.yaml
                        sed -i 's|{{GIT_COMMIT}}|${GIT_COMMIT}|g' k8s/backend/deployment.yaml
                        sed -i 's|{{BUILD_VERSION}}|${BUILD_VERSION}|g' k8s/backend/deployment.yaml
                        
                        sed -i 's|{{BUILD_TIMESTAMP}}|${BUILD_TIMESTAMP}|g' k8s/frontend/deployment.yaml
                        sed -i 's|{{GIT_COMMIT}}|${GIT_COMMIT}|g' k8s/frontend/deployment.yaml
                        sed -i 's|{{BUILD_VERSION}}|${BUILD_VERSION}|g' k8s/frontend/deployment.yaml
                        
                        echo "✅ Manifests updated for Minikube"
                    """
                    
                    // Apply Kubernetes configurations using minikube kubectl
                    sh """
                        echo "📋 Applying Kubernetes configurations to Minikube..."
                        
                        # Create namespace
                        minikube kubectl --profile=${MINIKUBE_PROFILE} -- apply -f k8s/namespace.yaml
                        
                        # Apply secrets and configmaps
                        minikube kubectl --profile=${MINIKUBE_PROFILE} -- apply -f k8s/secrets.yaml
                        minikube kubectl --profile=${MINIKUBE_PROFILE} -- apply -f k8s/configmap.yaml
                        
                        # Deploy MySQL
                        minikube kubectl --profile=${MINIKUBE_PROFILE} -- apply -f k8s/mysql/
                        
                        # Wait for MySQL to be ready
                        echo "⏳ Waiting for MySQL to be ready..."
                        minikube kubectl --profile=${MINIKUBE_PROFILE} -- wait --for=condition=ready pod -l app=mysql -n ${KUBE_NAMESPACE} --timeout=300s
                        
                        # Deploy backend and frontend
                        minikube kubectl --profile=${MINIKUBE_PROFILE} -- apply -f k8s/backend/
                        minikube kubectl --profile=${MINIKUBE_PROFILE} -- apply -f k8s/frontend/
                        
                        echo "✅ Kubernetes deployment to Minikube completed"
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
                    
                    // Test frontend
                    sh """
                        echo "🎨 Testing Frontend..."
                        if minikube kubectl --profile=${MINIKUBE_PROFILE} -- exec -n ${KUBE_NAMESPACE} deployment/frontend -- curl -s http://localhost:80/ > /dev/null; then
                            echo "✅ Frontend health check passed"
                        else
                            echo "❌ Frontend health check failed"
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
                        
                        # Get backend service URL  
                        echo "🔧 Backend URL:"
                        minikube service --profile=${MINIKUBE_PROFILE} --url backend-service -n ${KUBE_NAMESPACE} || echo "Backend service not available"
                        
                        # Show dashboard URL
                        echo "📊 Minikube Dashboard:"
                        minikube dashboard --profile=${MINIKUBE_PROFILE} --url || echo "Dashboard not available"
                    """
                    
                    // Show pod status
                    sh """
                        echo "📦 Pod Status:"
                        minikube kubectl --profile=${MINIKUBE_PROFILE} -- get pods -n ${KUBE_NAMESPACE}
                        
                        echo "🔧 Services:"
                        minikube kubectl --profile=${MINIKUBE_PROFILE} -- get services -n ${KUBE_NAMESPACE}
                    """
                }
            }
        }
    }
    
    post {
        always {
            // Cleanup workspace
            cleanWs()
            
            script {
                echo "📊 Build completed with status: ${currentBuild.currentResult}"
            }
        }
        success {
            echo "🎉 Pipeline executed successfully!"
            
            script {
                // Show final application access information
                sh """
                    echo " "
                    echo "🎯 APPLICATION ACCESS INFORMATION:"
                    echo "=================================="
                    echo "To access your application, run:"
                    echo "minikube service --profile=${MINIKUBE_PROFILE} frontend-service -n ${KUBE_NAMESPACE}"
                    echo " "
                    echo "Or use port-forward:"
                    echo "minikube kubectl --profile=${MINIKUBE_PROFILE} -- port-forward -n ${KUBE_NAMESPACE} service/frontend-service 8080:80"
                    echo " "
                    echo "View in browser: http://localhost:8080"
                    echo " "
                """
            }
        }
        failure {
            script {
                echo "💥 Pipeline failed! Initiating rollback..."
                
                // Rollback to previous version
                sh """
                    minikube kubectl --profile=${MINIKUBE_PROFILE} -- rollout undo deployment/backend -n ${KUBE_NAMESPACE} || true
                    minikube kubectl --profile=${MINIKUBE_PROFILE} -- rollout undo deployment/frontend -n ${KUBE_NAMESPACE} || true
                    
                    echo "🔄 Rollback attempted"
                """
            }
        }
    }
}