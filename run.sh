#!/bin/bash

do_run() {

  #
  # This program runs the service - it ensures that the ffmpeg in the github repository is on the PATH
  # and installs the python codebase using Pipenv. This initial build could take some time on the first run.
  # Subsequent runs _should_ be much faster.
  #

  export AWS_REGION="$(echo $(curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone) | sed 's/[a-z]$//')"
  echo $AWS_REGION
  echo $HOME
  whoami
  date -n
  pwd
  start_dir=$(cd "$(dirname $0)" && pwd)
  cd $start_dir
  echo "$start_dir"
  pwd
  pip3 install --user --upgrade pipenv
  export PATH=$PATH:/home/ec2-user/.local/bin/:/home/ec2-user/app/.github/workflows/bin/ffmpeg/
  ffmpeg -version
  pipenv install
  pipenv run python3 main.py
}

do_run >/home/ec2-user/run.log 2>&1
