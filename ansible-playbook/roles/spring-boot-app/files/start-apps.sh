#!/bin/bash
DOCKER_NAME="sb-apps-pro"
AF_DOCKER_NAME="sb-apps"

docker_process=$(sudo docker ps -a | grep $DOCKER_NAME | awk '{ print $1 }')
docker stop sb-apps || true && docker rm apps || true

# Standard Docker run DEV/CTC/PROD
sudo docker run -d -p 8080:8080 springio/gs-spring-boot-docker --restart

docker image prune -sb-apps
