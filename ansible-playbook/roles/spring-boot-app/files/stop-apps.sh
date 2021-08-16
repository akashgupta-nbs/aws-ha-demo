#!/bin/bash
DOCKER_NAME="sb-apps-pro"

echo "Stopping the sb-apps Service"
sudo docker stop $(sudo docker ps -a | grep $DOCKER_NAME | awk '{print $1}')
echo "Removing the sb-apps Service"
sudo docker rm $(sudo docker ps -a | grep $DOCKER_NAME | awk '{print $1}')
