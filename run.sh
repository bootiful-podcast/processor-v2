#!/bin/bash

do_run() {
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
