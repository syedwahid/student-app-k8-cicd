pipeline {
    agent any
    stages {
        stage('Test') {
            steps {
                script {
                    echo "🚀 Testing basic pipeline"
                    sh 'minikube version'
                    sh 'docker --version'
                    sh 'ls -la'
                }
            }
        }
    }
}