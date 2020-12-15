#!/usr/bin/env bash
set -e
set -o pipefail
APP_NAME=processor
PROJECT_ID=$GCLOUD_PROJECT
ROOT_DIR=$(cd $(dirname $0) && pwd)
BP_MODE_LOWERCASE=${BP_MODE_LOWERCASE:-development}
OD=${ROOT_DIR}/overlays/${BP_MODE_LOWERCASE}
SECRETS=${APP_NAME}-secrets
SECRETS_FN=${ROOT_DIR}/overlays/development/${APP_NAME}-secrets.env

export IMAGE_TAG="${BP_MODE_LOWERCASE}${GITHUB_SHA:-}"
export GCR_IMAGE_NAME=gcr.io/${PROJECT_ID}/${APP_NAME}
export IMAGE_NAME=${GCR_IMAGE_NAME}:${IMAGE_TAG}

echo "OD=$OD"
echo "BP_MODE_LOWERCASE=$BP_MODE_LOWERCASE"
echo "GCR_IMAGE_NAME=$GCR_IMAGE_NAME"
echo "IMAGE_NAME=$IMAGE_NAME"
echo "IMAGE_TAG=$IMAGE_TAG"

cd $ROOT_DIR/..

docker rmi $(docker images -a -q)
pack build -B heroku/buildpacks:18 $APP_NAME

image_id=$(docker images -q $APP_NAME)
docker tag "${image_id}" $IMAGE_NAME
docker push $IMAGE_NAME
echo "pushing ${image_id} to $IMAGE_NAME "
echo "tagging ${GCR_IMAGE_NAME}"

cd $ROOT_DIR
APP_YAML=${ROOT_DIR}/deploy/processor.yaml
APP_SERVICE_YAML=${ROOT_DIR}/deploy/processor-service.yaml
RMQ_USER=$BP_RABBITMQ_MANAGEMENT_USERNAME
RMQ_PW=$BP_RABBITMQ_MANAGEMENT_PASSWORD
#SECRETS_FN=${OD}/${APP_NAME}-secrets.env
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

cd $OD
kustomize edit set image $GCR_IMAGE_NAME=$IMAGE_NAME
kustomize build ${OD} | kubectl apply -f -

#kubectl apply -k ${OD}

rm $SECRETS_FN
