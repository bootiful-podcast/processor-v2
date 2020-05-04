#!/bin/bash

EC2_HOME=/home/ec2-user
APP_HOME=$EC2_HOME/app
LOG=$EC2_HOME/test.log
mkdir -p $APP_HOME
yum install -y python37 python37-pip git
mkdir -p $EC2_HOME
users  >> $EC2_HOME/users.txt
echo "$HOME $(whoami)" >> $LOG
su ec2-user 
echo "$HOME $(whoami) " >> $LOG
pip3 install pipenv supervisor
pipenv >> $LOG
git clone https://github.com/bootiful-podcast/python-test-to-deploy.git $APP_HOME

### supervisord
#cd $APP_HOME && pipenv install # && pipenv run python  main2.py
#echo "starting supervisor -y -qq..."
#sudo service start supervisor -y -qq
#CONF_FN=/etc/supervisor/conf.d/${SVC_NAME}.conf
#mkdir -p `dirname ${CONF_FN}`
#sudo cp ${ROOT_FS}/supervisor.conf ${CONF_FN}
#sudo supervisorctl update
#sudo supervisorctl reread