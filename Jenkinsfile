pipeline {
    agent any

    environment {
        AWS_REGION       = 'us-east-1' // Change to your AWS Region
        ECR_REGISTRY     = '544917027663.dkr.ecr.us-east-1.amazonaws.com'
        ECR_REPO         = 'todo-app'
        IMAGE_TAG        = "v${env.BUILD_NUMBER}"
        APP_NAME         = 'todo-application'
        K8S_NAMESPACE    = 'webapps'
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Build Docker Image') {
            steps {
                script {
                    echo "Building Docker image: ${ECR_REGISTRY}/${ECR_REPO}:${IMAGE_TAG}"
                    sh "docker build -t ${ECR_REGISTRY}/${ECR_REPO}:${IMAGE_TAG} ."
                }
            }
        }

        stage('Push to AWS ECR') {
            steps {
                // Requires 'aws-credentials' of type "AWS Credentials" configured in Jenkins
                withCredentials([[
                    $class: 'AmazonWebServicesCredentialsBinding',
                    credentialsId: 'aws-credentials',
                    accessKeyVariable: 'AWS_ACCESS_KEY_ID',
                    secretKeyVariable: 'AWS_SECRET_ACCESS_KEY'
                ]]) {
                    sh """
                        aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${ECR_REGISTRY}
                        docker push ${ECR_REGISTRY}/${ECR_REPO}:${IMAGE_TAG}
                    """
                }
            }
        }

        stage('Deploy to EKS') {
            steps {
                // Requires a "Secret text" credential named 'k8s-sa-token' and 'eks-api-url'
                withCredentials([
                    string(credentialsId: 'eks-api-url', variable: 'EKS_URL'),
                    string(credentialsId: 'k8s-sa-token', variable: 'K8S_TOKEN')
                ]) {
                    sh """
                        # 1. Substitute the image placeholder with the actual ECR URI
                        sed -i "s|IMAGE_PLACEHOLDER|${ECR_REGISTRY}/${ECR_REPO}:${IMAGE_TAG}|g" k8s/deployment-service.yaml
                        
                        # 2. Configure kubectl using the Service Account Token
                        kubectl config set-cluster my-eks --server=\${EKS_URL} --insecure-skip-tls-verify=true
                        kubectl config set-credentials jenkins-sa --token=\${K8S_TOKEN}
                        kubectl config set-context eks-context --cluster=my-eks --user=jenkins-sa --namespace=${K8S_NAMESPACE}
                        kubectl config use-context eks-context
                        
                        # 3. Apply manifests
                        kubectl apply -f k8s/rbac.yaml
                        kubectl apply -f k8s/deployment-service.yaml
                        
                        # 4. Verify deployment
                        kubectl rollout status deployment/taskmaster-deployment -n ${K8S_NAMESPACE}
                    """
                }
            }
        }
    }
    
    post {
        always {
            // Clean up local Docker images to free up space on the Ubuntu server
            sh "docker rmi ${ECR_REGISTRY}/${ECR_REPO}:${IMAGE_TAG} || true"
        }
    }
}
