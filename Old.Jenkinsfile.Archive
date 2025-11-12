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
                    buildImage("whispernet/java-app:${env.IMAGE_NAME}")
                    dockerLogin(credentialsId)
                    dockerPush("whispernet/java-app:${env.IMAGE_NAME}")
                }
            }
        }
        stage("deploy to ec2"){
            steps{
                script{
                    echo "Deploying the application"
                    def server = "ec2-user@98.89.35.103"
                    def imageName = "whispernet/java-app:${env.IMAGE_NAME}"
                    def shellCommand = "bash server-script.sh ${imageName}"
                    def filesToCopy = ["server-script.sh", "docker-compose.yaml"]
                    def credentialsId = "aws-lab-key"
                    def workSpace = "/home/ec2-user"
                    deployApp(server, shellCommand, filesToCopy, credentialsId, workSpace)
                }
            }
        }
        stage("Commit incremented version"){
            steps{
                script{
                    echo "Committing the incremented version"
                    def branch = "master"
                    def gitCreds = "deploy-key-jva"
                    def origin = "git@github.com:WhisperNet/java-app-cicd.git"
                    pushVersioIncrement(branch, gitCreds,origin)
                }
            }
        }
    }
}