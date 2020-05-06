#!/bin/bash

EC2_HOME=/home/ec2-user
APP_HOME=$EC2_HOME/app
LOG=$EC2_HOME/ec2-user-data-bootstrap.log

### REPLACE ME

PODCAST_RMQ_ADDRESS=_PODCAST_RMQ_ADDRESS_

### REPLACE ME

# this bit is to be replaced by a script
#https://medium.com/@benmorel/creating-a-linux-service-with-systemd-611b5c8b91d6
#https://www.linux.com/training-tutorials/understanding-and-using-systemd/

do_bootstrap() {
  mkdir -p $APP_HOME
  mkdir -p $EC2_HOME
  yum install -y python37 python37-pip git
  git clone https://github.com/bootiful-podcast/python-test-to-deploy.git $APP_HOME
  cd $APP_HOME
  chown -R ec2-user:ec2-user $APP_HOME
  SYSTEMD_SVC_NAME=bootiful-podcast-processor
  ENV_FILE=/home/ec2-user/app/environment
  mkdir -p "$(dirname $ENV_FILE)"
  echo "PODCAST_RMQ_ADDRESS=$PODCAST_RMQ_ADDRESS" > $ENV_FILE
  echo "" >> $ENV_FILE

  cp $APP_HOME/.github/workflows/${SYSTEMD_SVC_NAME}.service /etc/systemd/system/${SYSTEMD_SVC_NAME}.service
  echo $PODCAST_RMQ_ADDRESS >$APP_HOME/environment
  systemctl start $SYSTEMD_SVC_NAME
  systemctl enable $SYSTEMD_SVC_NAME
}

do_bootstrap >$LOG 2>&1
