# Design

## High Availability Design:

![image](https://user-images.githubusercontent.com/81324154/129489253-b928ff7a-5334-4835-92d8-0b01b1c41c67.png)

 1) **Application load balancer**: It gets the incoming traffic from route 53 and distribute incoming application traffic to multiple **nginx** node which acts as **reverse proxy** to send the traffic further to target servers( ec2 here) in **2 AZ.**
    - send matrics to CloudWatch
    - can notify overutilization and high latency
    - can alerts ec2 failures and other issues..
 2)** Auto scaling**: Upon failure of health check , it spins up the new target instance and make solution highly available.
 3) **Docker**: It helps to containerize application and restart the container if stop or failed due to any issues to make the application highly available. 


# Terraform Setup:

## Pre-requisite: Following software/tools to be installed on software to run terraform manifest:
  - terraform > 0.13
  - jq
  - awscli
  - nginx

## Login
Use the scripts/aws-creds.sh to login to aws and set the aws env variables ( secret, id etc)

## Create Application Infra
Current terraform manifest will help to create application infra which includes Application load balancer with auto scaling. Using user data , it helps to install require software and update package manager during bootstrap. 

# Playbook setup
Once the infra setup is done, ansible playbooks gets the host info list dynamically and play the configuration management task such as require software install, pull the application and deploy. 

# nginx setup
Install the nginx on servers through playbook and update the nginx configuration to set the proxy pass to localhost
proxy_pass http://localhost:8080/![image](https://user-images.githubusercontent.com/81324154/129527602-72109bff-0c8b-49ae-b0b5-10486c6eaf28.png)

# docker setup
Pull the spring boot image and run on this 8080 port on both the server
Use the restart flag to help restart the container in case of any issues. 
docker run -d -p 8080:8080 springio/gs-spring-boot-docker --restart

# ansible-playbook
Playbook task to help installing nginx on nodes and running  docker apps on server.
It also verify the localhost 8080 port for basic sanity of apps.
for production , prod hosts needs to be use. 
Default env would be dev env. 

ansible-playbook -i hosts site.yml

## Before nginx setup:
Gets the traffic from load balancer and distributes to both the nodes:

 ![image](https://user-images.githubusercontent.com/81324154/129528002-82bf463a-1d29-49ac-a634-8d63c2905dc8.png)


 ![image](https://user-images.githubusercontent.com/81324154/129528027-aa882b8e-e452-4cf4-ae5a-d9e595c41c86.png)

## After the nginx reverse proxy setup:
It sends the traffic to backend apps server:

 ![image](https://user-images.githubusercontent.com/81324154/129528135-27554d70-5a1c-48d5-93a4-e8052f59e3e3.png)


## End to end orchestration
Jenkins can be good choice of tool to automate end to end flow i.e. 
  - Add stages to create infra using terraform 
  - Add stages to trigger ansible playbook for configuration management. 
  - Add stages for deployment. 
  - Add stages to continous verificiation: Add testing stages to verify the application deployment. 


