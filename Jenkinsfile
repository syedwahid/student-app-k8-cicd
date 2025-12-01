pipeline {
    agent any
    
    environment {
        K8S_NAMESPACE = "student-app"
        BACKEND_IMAGE = "student-backend"
        FRONTEND_IMAGE = "student-frontend"
    }
    
    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }
        
        stage('Test Backend') {
            steps {
                dir('app/backend') {
                    script {
                        sh 'npm install'
                        sh 'npm test'
                    }
                }
            }
        }
        
        stage('Build Images') {
            steps {
                script {
                    // Build backend
                    dir('app/backend') {
                        sh "docker build -t ${BACKEND_IMAGE}:${BUILD_NUMBER} ."
                        sh "kind load docker-image ${BACKEND_IMAGE}:${BUILD_NUMBER} --name student-app"
                    }
                    
                    // Build frontend
                    dir('app/frontend') {
                        sh "docker build -t ${FRONTEND_IMAGE}:${BUILD_NUMBER} ."
                        sh "kind load docker-image ${FRONTEND_IMAGE}:${BUILD_NUMBER} --name student-app"
                    }
                }
            }
        }
        
        stage('Deploy to Kubernetes') {
            steps {
                script {
                    // Update backend image
                    sh """
                        kubectl set image deployment/backend-deployment \
                        backend=${BACKEND_IMAGE}:${BUILD_NUMBER} \
                        -n ${K8S_NAMESPACE}
                    """
                    
                    // Update frontend image
                    sh """
                        kubectl set image deployment/frontend-deployment \
                        frontend=${FRONTEND_IMAGE}:${BUILD_NUMBER} \
                        -n ${K8S_NAMESPACE}
                    """
                    
                    // Wait for rollout
                    sh "kubectl rollout status deployment/backend-deployment -n ${K8S_NAMESPACE} --timeout=300s"
                    sh "kubectl rollout status deployment/frontend-deployment -n ${K8S_NAMESPACE} --timeout=300s"
                }
            }
        }
        
        stage('Smoke Tests') {
            steps {
                script {
                    // Test via port-forward
                    sh """
                        kubectl port-forward -n ${K8S_NAMESPACE} service/backend-service 9081:3000 &
                        sleep 5
                        curl -f http://localhost:9081/api/health || exit 1
                    """
                }
            }
        }
    }
    
    post {
        always {
            sh 'pkill -f "kubectl port-forward" || true'
        }
        success {
            echo '🎉 Deployment successful!'
            sh """
                echo "Access your application:"
                echo "Frontend: http://localhost:30080/"
                echo "Backend API: Use port-forward as shown above"
            """
        }
        failure {
            echo '❌ Deployment failed! Rolling back...'
            sh "kubectl rollout undo deployment/backend-deployment -n ${K8S_NAMESPACE}"
            sh "kubectl rollout undo deployment/frontend-deployment -n ${K8S_NAMESPACE}"
        }
    }
}