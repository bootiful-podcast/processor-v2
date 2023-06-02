#!/usr/bin/env bash
set -e
set -o pipefail
APP_NAME=processor
SECRETS=${APP_NAME}-secrets
SECRETS_FN=${ROOT_DIR}/${APP_NAME}-secrets

export IMAGE_TAG="${GITHUB_SHA:-}"
export GCR_IMAGE_NAME=gcr.io/${GCLOUD_PROJECT}/${APP_NAME}
export IMAGE_NAME=${GCR_IMAGE_NAME}:${IMAGE_TAG}

echo "OD=$OD"
echo "BP_MODE_LOWERCASE=$BP_MODE_LOWERCASE"
echo "GCR_IMAGE_NAME=$GCR_IMAGE_NAME"
echo "IMAGE_NAME=$IMAGE_NAME"
echo "IMAGE_TAG=$IMAGE_TAG"

cd $GITHUB_WORKSPACE
# docker rmi $(docker images -a -q)
# pack build -B heroku/builder:22 $APP_NAME
# pack build -B heroku/buildpacks:20 $APP_NAME

docker build -t $IMAGE_NAME . # Will be named dude/man:v2

# docker build . 

image_id=$(docker images -q $APP_NAME)
docker tag "${image_id}" $IMAGE_NAME
docker push $IMAGE_NAME
echo "pushing ${image_id} to $IMAGE_NAME "
echo "tagging ${GCR_IMAGE_NAME}"

cd $ROOT_DIR
APP_YAML=${ROOT_DIR}/deploy/processor.yaml
APP_SERVICE_YAML=${ROOT_DIR}/deploy/processor-service.yaml
rm -rf $SECRETS_FN
touch $SECRETS_FN
echo writing to "$SECRETS_FN "
cat <<EOF >${SECRETS_FN}
PODCAST_RMQ_ADDRESS=amqp://${BP_RABBITMQ_MANAGEMENT_USERNAME}:${BP_RABBITMQ_MANAGEMENT_PASSWORD}@${BP_RABBITMQ_MANAGEMENT_HOST}/${BP_RABBITMQ_MANAGEMENT_VHOST}
BP_MODE=${BP_MODE_LOWERCASE}
AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID
AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY
AWS_REGION=$AWS_REGION
EOF

echo "SECRETS==========="
echo $SECRETS_FN
kubectl delete secrets $SECRETS || echo "no secrets to delete."
kubectl create secret generic $SECRETS --from-env-file $SECRETS_FN
kubectl delete -f $ROOT_DIR/deploy/k8s/deployment.yaml || echo "couldn't delete the deployment as there was nothing deployed."
kubectl apply -f $ROOT_DIR/deploy/k8s