#!/usr/bin/env bash
set -e
set -o pipefail

ROOT_DIR=$(cd $(dirname $0)/.. && pwd)
APP_NAME=processor
PROJECT_ID=$GCLOUD_PROJECT

cd $ROOT_DIR


pack build -B heroku/buildpacks:18 $APP_NAME
image_id=$(docker images -q $APP_NAME)
docker tag "${image_id}" gcr.io/${PROJECT_ID}/${APP_NAME}
docker push gcr.io/${PROJECT_ID}/${APP_NAME}
docker pull gcr.io/${PROJECT_ID}/${APP_NAME}:latest

APP_YAML=${ROOT_DIR}/deploy/processor.yaml
APP_SERVICE_YAML=${ROOT_DIR}/deploy/processor-service.yaml
SECRETS=${APP_NAME}-secrets
RMQ_USER=$(read_kubernetes_secret rabbitmq-secrets RABBITMQ_DEFAULT_USER)
RMQ_PW=$(read_kubernetes_secret rabbitmq-secrets RABBITMQ_DEFAULT_PASS)

kubectl delete secrets ${SECRETS} || echo "could not delete ${SECRETS}."
kubectl delete -f "$APP_YAML" || echo "could not delete the existing Kubernetes environment as described in ${APP_YAML}."
kubectl apply -f <(echo "
---
apiVersion: v1
kind: Secret
metadata:
  name: ${SECRETS}
type: Opaque
stringData:
  PODCAST_RMQ_ADDRESS: amqp://${RMQ_USER}:${RMQ_PW}@rabbitmq/
  AWS_ACCESS_KEY_ID: "${AWS_ACCESS_KEY_ID}"
  AWS_SECRET_ACCESS_KEY: "${AWS_SECRET_ACCESS_KEY}"
  AWS_REGION: "${AWS_REGION}"
")

kubectl apply -f $APP_YAML
kubectl get service | grep $APP_NAME || kubectl apply -f $APP_SERVICE_YAML


#kubectl create deployment ${APP_NAME} --image=gcr.io/${PROJECT_ID}/${APP_NAME}
#kubectl expose deployment ${APP_NAME} --port=80 --target-port=8080 --name=${APP_NAME} --type=LoadBalancer
#kubectl describe services $APP_NAME
