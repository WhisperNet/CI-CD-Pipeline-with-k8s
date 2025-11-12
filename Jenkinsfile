#!/usr/bin/env groovy
library identifier: 'jenkins-shared-library-master@main', retriever: modernSCM(
    [$class: 'GitSCMSource',
    remote: 'https://github.com/WhisperNet/jenkins-shared-library-master.git'
    ]
)
pipeline {
    agent any
    tools {
        maven 'maven-3.9.11'
    }
    stages {
        stage("test"){
            steps {
                script{
                    sh "mvn test"
                }
            }
        }
        stage("Increment version"){
            steps{
                script{
                    incrementVersionMvn()
                }
            }
        }
        stage("build jar"){
            steps{
                script{
                    echo "Building jar"
                    buildJar()
                }
            }
        }
        stage("build and push docker image"){
            steps{
                script{
                    echo "Building and pushing the docker image"
                    def credentialsId = "docker-hub"
                    buildImage("whispernet/java-app-k8s-cicd:${env.IMAGE_NAME}")
                    dockerLogin(credentialsId)
                    dockerPush("whispernet/java-app-k8s-cicd:${env.IMAGE_NAME}")
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
                    sh 'envsubst < java-depl.yaml >> java-depl-tmp.yaml'
                    sh 'kubectl apply -f java-depl-tmp.yaml'
                    sh 'rm java-depl-tmp.yaml'
                }
            }
        }
        stage("Commit incremented version"){
            steps{
                script{
                    echo "Committing the incremented version"
                    def branch = "master"
                    def gitCreds = "deploy-key-jva"
                    def origin = "git@github.com:WhisperNet/CI-CD-Pipeline-with-k8s.git"
                    pushVersioIncrement(branch, gitCreds,origin)
                }
            }
        }
    }

}