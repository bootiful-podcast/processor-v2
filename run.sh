#!/bin/bash

do_run() {
  echo $HOME
  whoami
  pwd
  start_dir=$(cd "$(dirname $0)" && pwd)
  cd $start_dir
  echo "$start_dir"
  pwd
  pip3 install --user --upgrade pipenv
  PATH=$PATH:/home/ec2-user/.local/bin/
  pipenv install
  pipenv run python3 main2.py
}

do_run >/home/ec2-user/run.log 2>&1
