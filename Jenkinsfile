#!/usr/bin/env groovy

pipeline {
    agent any
    stages{
        stage('build app'){
            steps{
                script{
                    echo "Building the application"
                }
            }
        }
        stage('build and push image') {
            steps{
                script {
                    echo "Building image"
                    echo "Pushing image"
                }
            }
        }
        stage('deploy to k8s') {
            environment {
                AWS_ACCESS_KEY_ID = credentials('aws_access_key_id')
                AWS_SECRET_ACCESS_KEY = credentials('aws_secret_accesss_key')
            }
            steps{
                script{
                    echo "Deploying nginx image to the eks"
                    sh 'kubectl create deployment nginx-deployment --image=nginx'
                }
            }
        }
    }
}