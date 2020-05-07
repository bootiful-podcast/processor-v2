#!/bin/bash

EC2_HOME=/home/ec2-user
APP_HOME=$EC2_HOME/app
LOG=$EC2_HOME/ec2-user-data-bootstrap.log
ENV_FILE=$APP_HOME/environment
SYSTEMD_SVC_NAME=bootiful-podcast-processor

### REPLACE ME

PODCAST_RMQ_ADDRESS=_PODCAST_RMQ_ADDRESS_

GITHUB_SHA=_GITHUB_SHA_

### REPLACE ME

# this bit is to be replaced by a script
# https://medium.com/@benmorel/creating-a-linux-service-with-systemd-611b5c8b91d6
# https://www.linux.com/training-tutorials/understanding-and-using-systemd/
# https://www.johnvansickle.com/ffmpeg/ <- statically linked ffmpeg binaries

do_bootstrap() {
  mkdir -p $APP_HOME
  mkdir -p $EC2_HOME

  ### FFMPEG

#  curl https://johnvansickle.com/ffmpeg/releases/ffmpeg-release-amd64-static.tar.xz --output $HOME/ffmpeg.tar.xz
#  tar xpf $HOME/ffmpeg.tar.xz --directory $HOME/bin
#  cd $HOME/bin
  ### FFMPEG
#  export PATH=$PATH:
#  $HOME/app/.github/workflows/bin/ffmpeg


  yum install -y python37 python37-pip git
  ### todo figure out how to get ffmpeg installed!
  ### todo https://www.johnvansickle.com/ffmpeg/

  # yum install -y autoconf automake bzip2 bzip2-devel cmake freetype-devel gcc gcc-c++ git libtool make mercurial pkgconfig zlib-devel

  echo "the github SHA is ${GITHUB_SHA} "
  git clone https://github.com/bootiful-podcast/python-test-to-deploy.git $APP_HOME
  cd $APP_HOME
  git checkout $GITHUB_SHA
  chown -R ec2-user:ec2-user $APP_HOME

  touch $ENV_FILE
  echo "PODCAST_RMQ_ADDRESS=$PODCAST_RMQ_ADDRESS" >>$ENV_FILE
  echo "CONFIG_FILE_NAME=$CONFIG_FILE_NAME" >>$ENV_FILE

  cp $APP_HOME/.github/workflows/${SYSTEMD_SVC_NAME}.service /etc/systemd/system/${SYSTEMD_SVC_NAME}.service

  systemctl start $SYSTEMD_SVC_NAME
  systemctl enable $SYSTEMD_SVC_NAME


}

do_bootstrap >$LOG 2>&1
