#!/bin/sh
KEYPAIR=bootiful-podcast_processor_05-02-2020
SECURITY_GROUP=web-host
AMI_ID=ami-06fcc1f0bc2c8943f
REGION=us-west-1
INSTANCE_TYPE=t1.micro
USER_DATA=$(curl https://raw.githubusercontent.com/bootiful-podcast/processor-installer/7bd3ec8193301f1da228465b92c4d98ae88e9619/assets/bootstrap.sh)
aws ec2 run-instances --image-id $AMI_ID --region $REGION --count 1 --instance-type $INSTANCE_TYPE --key-name $KEYPAIR --security-groups $SECURITY_GROUP --user-data "$USER_DATA"
