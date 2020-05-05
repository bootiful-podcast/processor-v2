#!/bin/sh
AMI_ID=ami-0d6621c01e8c2de2c
AWS_REGION=us-west-2
INSTANCE_TYPE=t3.large
SUBNET_ID=subnet-05ec18a303fb18a5c
SECURITY_GROUP_NAME=bootiful-podcast-sg
USER_DATA_URL=https://raw.githubusercontent.com/bootiful-podcast/python-test-to-deploy/master/.github/workflows/bootstrap.sh
KEYPAIR_NAME=bootiful-podcast-${RANDOM}
KEYPAIR_FILE=$HOME/Desktop/${KEYPAIR_NAME}.pem

## Requirements:
### - subnet
### - keypair
### - vpc
# https://howtodoinjava.com/aws/create-connect-aws-ec2-ssh-puttygen/
# https://treyperry.com/2015/06/22/ipv4-cidr-vpc-in-a-nutshell/
# https://sysadmins.co.za/aws-create-a-vpc-and-launch-ec2-instance-using-the-cli/
# https://chartio.com/resources/tutorials/connecting-to-a-database-within-an-amazon-vpc/
# https://ryanstutorials.net/bash-scripting-tutorial/bash-if-statements.php

### VPC
if [ "$(aws ec2 describe-vpcs --region $AWS_REGION | jq -r ' .Vpcs | length ' | grep 0)" = "0" ]; then
  VPC_ID=$(aws ec2 create-vpc --cidr-block 192.168.0.0/16 --region $AWS_REGION | jq -r '.Vpc.VpcId')
  aws ec2 modify-vpc-attribute --vpc-id "$VPC_ID" --region $AWS_REGION --enable-dns-support "{\"Value\":true}"
  aws ec2 modify-vpc-attribute --vpc-id "$VPC_ID" --region $AWS_REGION --enable-dns-hostnames "{\"Value\":true}"
fi

VPC_ID=$(aws ec2 describe-vpcs --region $AWS_REGION | jq -r '.Vpcs[0].VpcId')
echo "VPC_ID=$VPC_ID"

### Internet Gateway
if [ "$(aws ec2 describe-internet-gateways --region $AWS_REGION | jq -r '.InternetGateways | length ' | grep 0)" = "0" ]; then
  IG_ID=$(aws ec2 create-internet-gateway --region $AWS_REGION | jq -r '.InternetGateway.InternetGatewayId')
  aws ec2 attach-internet-gateway --internet-gateway-id $IG_ID --vpc-id $VPC_ID --region $AWS_REGION
fi

IG_ID=$(aws ec2 describe-internet-gateways --region $AWS_REGION | jq -r '.InternetGateways[0].InternetGatewayId')
echo "IG_ID=${IG_ID}"

### Subnet
if [ "$(aws ec2 describe-subnets --region $AWS_REGION | jq -r '.Subnets | length' | grep 0)" = "0" ]; then
  SUBNET_ID=$(aws ec2 create-subnet --vpc-id $VPC_ID --cidr-block 192.168.0.0/16 --region $AWS_REGION | jq -r '.Subnet.SubnetId')
fi

SUBNET_ID=$(aws ec2 describe-subnets --region $AWS_REGION | jq -r '.Subnets[0].SubnetId')
echo "SUBNET_ID=$SUBNET_ID"

### Route Tables
### We don't create a new one because it's already done when we create the stuff above. (Should we?)
ROUTE_TABLE_ID=$(aws ec2 describe-route-tables --region $AWS_REGION | jq -r '.RouteTables[0].RouteTableId')
aws ec2 associate-route-table --route-table-id $ROUTE_TABLE_ID --subnet-id $SUBNET_ID --region $AWS_REGION >/dev/null
aws ec2 create-route --route-table-id $ROUTE_TABLE_ID --destination-cidr-block 0.0.0.0/0 --gateway-id $IG_ID --region $AWS_REGION >/dev/null
echo "ROUTE_TABLE_ID=$ROUTE_TABLE_ID"

### Security Group
if [ "$(aws ec2 describe-security-groups --region $AWS_REGION | jq -r '.SecurityGroups[].GroupName' | grep $SECURITY_GROUP_NAME)" = "" ]; then
  SG_ID=$(aws ec2 create-security-group --group-name "$SECURITY_GROUP_NAME" --description "$SECURITY_GROUP_NAME" --vpc-id "$VPC_ID" --region $AWS_REGION | jq -r '.GroupId')
  aws ec2 authorize-security-group-ingress --group-id $SG_ID --protocol tcp --port 22 --cidr 0.0.0.0/0 --region $AWS_REGION
  aws ec2 authorize-security-group-ingress --group-id $SG_ID --protocol tcp --port 8080 --cidr 0.0.0.0/0 --region $AWS_REGION
fi

SG_ID=$(aws ec2 describe-security-groups --region $AWS_REGION | jq -r ' .[] | map(select (.GroupName == "bootiful-podcast-sg") ) | .[0].GroupId ')
echo "SG_ID=$SG_ID"

### Keypair
if [ "$(aws ec2 describe-key-pairs --region $AWS_REGION | jq -r '.KeyPairs[].KeyName ' | grep $KEYPAIR_NAME)" = "" ]; then
  aws ec2 create-key-pair --region $AWS_REGION --key-name $KEYPAIR_NAME --query 'KeyMaterial' --output text >$KEYPAIR_FILE
  chmod 400 $KEYPAIR_FILE
fi

## Go time
IMAGE_NAME=$(aws ec2 describe-images --region $AWS_REGION --owners amazon --filters 'Name=name,Values=amzn-ami-hvm-????.??.?.x86_64-gp2' 'Name=state,Values=available' | jq -r '.Images | sort_by(.CreationDate) | last(.[]).ImageId')
echo "going to launch $IMAGE_NAME "

INSTANCE_ID=$(aws ec2 run-instances --region $AWS_REGION --image-id $IMAGE_NAME --count 1 --instance-type $INSTANCE_TYPE --key-name $KEYPAIR_NAME --security-group-ids $SG_ID --subnet-id $SUBNET_ID --associate-public-ip-address | jq -r  '.Instances[0].InstanceId')
echo "INSTANCE_ID=$INSTANCE_ID"
DNS_NAME=$(aws ec2 describe-instances --region $AWS_REGION --instance-ids $INSTANCE_ID --query 'Reservations[0].Instances[0].PublicDnsName')
echo "DNS_NAME=$DNS_NAME"

#ssh -i ~/.ssh/myKey.pem ec2-user@ec2-34-12-34-56.eu-west-1.compute.amazonaws.com
#
#```language-bash
#$ aws ec2 run-instances --image-id ami-f9dd458a --count 1 --instance-type t2.micro --key-name myKey --security-group-ids <returned-security-groupid> --subnet-id <returned-subnetid> --associate-public-ip-address --query 'Instances[0].InstanceId'
#"i-1234528abce88b44"
#``` <p>
#
#Get the Public IP by calling the Describe-Instances API call:
#
#```language-bash
#$ aws ec2 describe-instances --instance-ids <returned-instance-id --query 'Reservations[0].Instances[0].PublicDnsName'
#"ec2-34-12-34-56.eu-west-1.compute.amazonaws.com"
#``` <p>
#
#SSH into your EC2 Instance with your KeyPair and Public IP:
#
#```language-bash
#$ ssh -i ~/.ssh/myKey.pem ec2-user@ec2-34-12-34-56.eu-west-1.compute.amazonaws.com
#[ec2-user@ip-192-168-103-84 ~]$
#``` <p>
#
#Aditionally, you can also tag your resource, by doing the following:
#
#```language-bash
#$ aws ec2 create-tags --resources "i-1234528abce88b44" --tags 'Key="ENV",Value=DEV'
#``` <p>
