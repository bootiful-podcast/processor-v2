#!/bin/bash

function install() {
  EC2_HOME=/home/ec2-user
  APP_HOME=$EC2_HOME/app
  LOG=$EC2_HOME/test.log
  mkdir -p $APP_HOME
  yum install -y python37 python37-pip git
  mkdir -p $EC2_HOME
  users
  su ec2-user
  pip3 install pipenv supervisor
  git clone https://github.com/bootiful-podcast/python-test-to-deploy.git $APP_HOME
  cd $APP_HOME
  pipenv run python3 main2.py
}

install >> $LOG

### supervisord
#cd $APP_HOME && pipenv install # && pipenv run python  main2.py
#echo "starting supervisor -y -qq..."
#sudo service start supervisor -y -qq
#CONF_FN=/etc/supervisor/conf.d/${SVC_NAME}.conf
#mkdir -p `dirname ${CONF_FN}`
#sudo cp ${ROOT_FS}/supervisor.conf ${CONF_FN}
#sudo supervisorctl update
#sudo supervisorctl reread
