@Library('platform-lib') _

pipeline {
    agent any

    options {
        timestamps()
        ansiColor('xterm')
        disableConcurrentBuilds()
        buildDiscarder(logRotator(numToKeepStr: '20'))
    }

    environment {
        PROJECT_ID = "${env.PROJECT_ID ?: 'your-gcp-project-id'}"
        REGION     = "${env.REGION ?: 'us-central1'}"
        AR_HOST    = "${REGION}-docker.pkg.dev"
        AR_REPO    = "${AR_HOST}/${PROJECT_ID}/jenkins-demo"
        IMAGE      = "${AR_REPO}/demo:${env.GIT_COMMIT ? env.GIT_COMMIT.take(7) : 'latest'}"
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Test') {
            steps {
                script {
                    runTests(context: 'app')
                }
            }
        }

        stage('Build image') {
            steps {
                script {
                    buildImage(image: env.IMAGE, context: 'app')
                }
            }
        }

        stage('Scan image') {
            steps {
                script {
                    scanImage(image: env.IMAGE)
                }
            }
        }

        stage('Push image') {
            steps {
                script {
                    pushImage(image: env.IMAGE)
                }
            }
        }

        stage('Deploy to Cloud Run') {
            steps {
                script {
                    deployToRun(
                        project: env.PROJECT_ID,
                        region: env.REGION,
                        image: env.IMAGE,
                        service: 'demo'
                    )
                }
            }
        }
    }

    post {
        success {
            echo "Pipeline succeeded for ${env.IMAGE}"
        }
        failure {
            echo "Pipeline failed for ${env.IMAGE}"
        }
        always {
            cleanWs()
        }
    }
}
