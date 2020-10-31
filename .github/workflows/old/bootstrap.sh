#!/bin/bash

EC2_HOME=/home/ec2-user
APP_HOME=$EC2_HOME/app
LOG=$EC2_HOME/ec2-user-data-bootstrap.log
ENV_FILE=$APP_HOME/environment
SYSTEMD_SVC_NAME=bootiful-podcast-processor

### REPLACE ME

PODCAST_RMQ_ADDRESS=_PODCAST_RMQ_ADDRESS_

BP_MODE=_BP_MODE_

GITHUB_SHA=_GITHUB_SHA_

### REPLACE ME

do_bootstrap() {
  mkdir -p $APP_HOME
  mkdir -p $EC2_HOME

  yum install -y python37 python37-pip git

  echo "the github SHA is ${GITHUB_SHA} "
  git clone https://github.com/bootiful-podcast/python-test-to-deploy.git $APP_HOME
  cd $APP_HOME
  git checkout $GITHUB_SHA
  chown -R ec2-user:ec2-user $APP_HOME

  touch $ENV_FILE
  echo "PODCAST_RMQ_ADDRESS=$PODCAST_RMQ_ADDRESS" >>$ENV_FILE
  echo "AWS_REGION=$AWS_REGION" >>$ENV_FILE
  echo "CONFIG_FILE_NAME=$CONFIG_FILE_NAME" >>$ENV_FILE
  echo "BP_MODE=$BP_MODE" >>$ENV_FILE

  cp $APP_HOME/.github/workflows/${SYSTEMD_SVC_NAME}.service /etc/systemd/system/${SYSTEMD_SVC_NAME}.service

  systemctl start $SYSTEMD_SVC_NAME
  systemctl enable $SYSTEMD_SVC_NAME

}

do_bootstrap >$LOG 2>&1
