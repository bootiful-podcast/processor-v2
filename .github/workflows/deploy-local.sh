#!/bin/sh
KEYPAIR=bootiful-podcast_processor_05-02-2020
SECURITY_GROUP=web-host
AMI_ID=ami-06fcc1f0bc2c8943f
REGION=us-west-1
INSTANCE_TYPE=t2.large
USER_DATA_URL=https://raw.githubusercontent.com/bootiful-podcast/python-test-to-deploy/${GITHUB_SHA}/.github/workflows/bootstrap.sh
USER_DATA=$(curl $USER_DATA_URL )
aws ec2 run-instances --region $AWS_REGION --image-id $AMI_ID --count 1 --instance-type $INSTANCE_TYPE --key-name $KEYPAIR --security-groups $SECURITY_GROUP --user-data "$USER_DATA"

