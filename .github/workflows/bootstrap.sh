#!/bin/bash

EC2_HOME=/home/ec2-user
yum install -y python37 python37-pip git 

mkdir -p $EC2_HOME
users  > $EC2_HOME/users.txt
echo "$HOME $(whoami)" > $EC2_HOME/first.txt
su ec2-user 
echo "$HOME $(whoami) " > $EC2_HOME/second.txt
pip3 install pipenv 
pipenv > $EC2_HOME/pipenv-status.txt