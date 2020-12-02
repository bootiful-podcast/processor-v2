#!/usr/bin/env bash
set -e
set -o pipefail
APP_NAME=processor
PROJECT_ID=$GCLOUD_PROJECT
ROOT_DIR=$(cd $(dirname $0) && pwd)
BP_MODE_LOWERCASE=${BP_MODE_LOWERCASE:-development}
OD=${ROOT_DIR}/overlays/${BP_MODE_LOWERCASE}
SECRETS=${APP_NAME}-secrets
SECRETS_FN=${OD}/${APP_NAME}-secrets.env

cd $ROOT_DIR/..

pack build -B heroku/buildpacks:18 $APP_NAME
image_id=$(docker images -q $APP_NAME)
docker tag "${image_id}" gcr.io/${PROJECT_ID}/${APP_NAME}
docker push gcr.io/${PROJECT_ID}/${APP_NAME}
docker pull gcr.io/${PROJECT_ID}/${APP_NAME}:latest


cd $ROOT_DIR
APP_YAML=${ROOT_DIR}/deploy/processor.yaml
APP_SERVICE_YAML=${ROOT_DIR}/deploy/processor-service.yaml
RMQ_USER=$BP_RABBITMQ_MANAGEMENT_USERNAME
RMQ_PW=$BP_RABBITMQ_MANAGEMENT_PASSWORD
SECRETS_FN=${OD}/${APP_NAME}-secrets.env
rm -rf $SECRETS_FN
touch $SECRETS_FN
echo writing to "$SECRETS_FN "
cat <<EOF >${SECRETS_FN}
PODCAST_RMQ_ADDRESS=amqp://${RMQ_USER}:${RMQ_PW}@rabbitmq/
BP_MODE=${BP_MODE_LOWERCASE}
AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID
AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY
AWS_REGION=$AWS_REGION
EOF

kubectl apply -k ${OD}

rm $SECRETS_FN


#kubectl delete secrets ${SECRETS} || echo "could not delete ${SECRETS}."
#kubectl delete -f "$APP_YAML" || echo "could not delete the existing Kubernetes environment as described in ${APP_YAML}."
#kubectl apply -f <(echo "
#---
#apiVersion: v1
#kind: Secret
#metadata:
#  name: ${SECRETS}
#type: Opaque
#stringData:
#  PODCAST_RMQ_ADDRESS: amqp://${RMQ_USER}:${RMQ_PW}@rabbitmq/
#  BP_MODE: "${BP_MODE_LOWERCASE}"
#  AWS_ACCESS_KEY_ID: "${AWS_ACCESS_KEY_ID}"
#  AWS_SECRET_ACCESS_KEY: "${AWS_SECRET_ACCESS_KEY}"
#  AWS_REGION: "${AWS_REGION}"
#")
#
#kubectl apply -f $APP_YAML
#kubectl get service | grep $APP_NAME || kubectl apply -f $APP_SERVICE_YAML

#kubectl create deployment ${APP_NAME} --image=gcr.io/${PROJECT_ID}/${APP_NAME}
#kubectl expose deployment ${APP_NAME} --port=80 --target-port=8080 --name=${APP_NAME} --type=LoadBalancer
#kubectl describe services $APP_NAME
