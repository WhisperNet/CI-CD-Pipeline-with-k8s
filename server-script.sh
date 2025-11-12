#!/bin/bash
export IMAGE=$1
docker compose -f docker-compose.yaml up -d
echo "Server is running on port 8080"
