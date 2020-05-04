#!/bin/sh
#KEYPAIR=bootiful-podcast_processor_05-02-2020
#SECURITY_GROUP=web-host
#AMI_ID=ami-06fcc1f0bc2c8943f
#REGION=us-west-1
#INSTANCE_TYPE=t1.micro
USER_DATA=$(curl https://raw.githubusercontent.com/bootiful-podcast/python-test-to-deploy/${GITHUB_SHA}/.github/workflows/bootstrap.sh )
aws ec2 run-instances --region $AWS_REGION --image-id $AMI_ID --region $REGION --count 1 --instance-type $INSTANCE_TYPE --key-name $KEYPAIR --security-groups $SECURITY_GROUP --user-data "$USER_DATA"
