#!/bin/sh
KEYPAIR=udemy-aws-oregon
#SECURITY_GROUP=web-host
SECURITY_GROUP=launch-wizard-1
AMI_ID=ami-0d6621c01e8c2de2c
AWS_REGION=us-west-2
INSTANCE_TYPE=t3.large
SUBNET_ID=subnet-05ec18a303fb18a5c
USER_DATA_URL=https://raw.githubusercontent.com/bootiful-podcast/python-test-to-deploy/master/.github/workflows/bootstrap.sh
USER_DATA=$(curl $USER_DATA_URL )
#aws ec2 run-instances --region $AWS_REGION --image-id $AMI_ID --count 1 --instance-type $INSTANCE_TYPE --key-name $KEYPAIR --security-groups $SECURITY_GROUP --user-data "$USER_DATA" --subnet $SUBNET_ID
aws ec2 run-instances --region $AWS_REGION --image-id $AMI_ID --count 1 --instance-type $INSTANCE_TYPE --key-name $KEYPAIR   --user-data "$USER_DATA" --subnet $SUBNET_ID


