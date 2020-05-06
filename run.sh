#!/bin/bash

LOG=/home/ec2-user/out.txt
pwd >>$LOG
start_dir=$(cd "$(dirname $0)" && pwd)
cd $start_dir
echo $start_dir >>$LOG
pwd >>$LOG
pip3 install --user --upgrade pipenv >> $LOG
pipenv install >> $LOG
pipenv run python3 main2.py  >> $LOG
