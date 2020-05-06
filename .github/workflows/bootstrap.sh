#!/bin/bash

EC2_HOME=/home/ec2-user
APP_HOME=$EC2_HOME/app
LOG=$EC2_HOME/ec2-user-data-bootstrap.log

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
  cp $APP_HOME/.github/workflows/${SYSTEMD_SVC_NAME}.service /etc/systemd/system/${SYSTEMD_SVC_NAME}.service
  systemctl start $SYSTEMD_SVC_NAME
  systemctl enable $SYSTEMD_SVC_NAME
}

do_bootstrap >$LOG 2>&1

### supervisord
#cd $APP_HOME && pipenv install # && pipenv run python main2.py
#echo "starting supervisor -y -qq..."
#sudo service start supervisor -y -qq
#CONF_FN=/etc/supervisor/conf.d/${SVC_NAME}.conf
#mkdir -p `dirname ${CONF_FN}`
#sudo cp ${ROOT_FS}/supervisor.conf ${CONF_FN}
#sudo supervisorctl update
#sudo supervisorctl reread
