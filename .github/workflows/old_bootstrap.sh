#!/bin/bash
#
#while [ ! -f /var/lib/cloud/instance/boot-finished ]; do
#  echo 'Waiting for cloud-init...'
#  sleep 1
#done
#


PROCESSOR_DIR=$HOME/processor
GIT_REPO=https://github.com/bootiful-podcast/python-test-to-deploy.git
rm -rf $PROCESSOR_DIR
git clone $GIT_REPO $PROCESSOR_DIR
cd $PROCESSOR_DIR

python3 -m pipenv install
python3 -m pipenv run python ${PROCESSOR_DIR}/config_aws.py $HOME/.aws/

SVC_DIR=${PROCESSOR_DIR}/service
SVC_ENV=${SVC_DIR}/processor-environment.sh
SVC_INIT=${SVC_DIR}/processor-service.sh

cat $HOME/env.sh >>${SVC_ENV}

${SVC_DIR}/install.sh
