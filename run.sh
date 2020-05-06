#!/bin/bash

LOG=/home/ec2-user/out.txt
pwd >>$LOG
start_dir=$(cd "$(dirname $0)" && pwd)
cd $start_dir
echo $start_dir >>$LOG
pwd >>$LOG
pip3 install --user --upgrade pipenv >>$LOG

PIPENV_PATH=/home/ec2-user/.local/bin/
PATH=$PATH:$PIPENV_PATH

pipenv install >>$LOG
pipenv run python3 main2.py >>$LOG
