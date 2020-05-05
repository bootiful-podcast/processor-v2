#!/bin/sh
KEYPAIR=udemy-aws-oregon
SECURITY_GROUP=bootiful-podcast-sg-default
AMI_ID=ami-0d6621c01e8c2de2c
AWS_REGION=us-west-2
INSTANCE_TYPE=t3.large
SUBNET_ID=subnet-05ec18a303fb18a5c
USER_DATA_URL=https://raw.githubusercontent.com/bootiful-podcast/python-test-to-deploy/master/.github/workflows/bootstrap.sh
USER_DATA=$(curl $USER_DATA_URL)

## Requirements:
### - subnet
### - keypair
### - vpc
# https://howtodoinjava.com/aws/create-connect-aws-ec2-ssh-puttygen/
# https://treyperry.com/2015/06/22/ipv4-cidr-vpc-in-a-nutshell/
# https://sysadmins.co.za/aws-create-a-vpc-and-launch-ec2-instance-using-the-cli/
# https://chartio.com/resources/tutorials/connecting-to-a-database-within-an-amazon-vpc/
#

## VPC_ID
## this looks to see if there are any VPCs. if there are, we'll use that one. if not, we'll create the instance here.
aws ec2 describe-vpcs --region $AWS_REGION | jq -r ' .Vpcs | length ' | grep 0 &&
  echo "No VPC instances found" && aws ec2 create-vpc --cidr-block 192.168.0.0/16 --region $AWS_REGION || echo "there's a VPC instance already. Let's find that."
VPC_ID=$(aws ec2 describe-vpcs --region $AWS_REGION | jq -r '.Vpcs[0].VpcId')
echo "using the VPC ${VPC_ID}."
#VPC->Edit DNS hostnames->Enable
aws ec2 modify-vpc-attribute --enable-dns-support "{\"Value\":true}" --region $AWS_REGION --vpc-id $VPC_ID
aws ec2 modify-vpc-attribute --enable-dns-hostnames "{\"Value\":true}" --region $AWS_REGION --vpc-id $VPC_ID

## Internet Gateway
IG_ID=$(aws ec2 create-internet-gateway --region $AWS_REGION | jq -r '.InternetGateway.InternetGatewayId')
echo "the internet gateway ID is $IG_ID"
aws ec2 attach-internet-gateway --internet-gateway-id $IG_ID --vpc-id $VPC_ID --region $AWS_REGION

## SUBNET_ID
#aws ec2 describe-subnets --region $AWS_REGION | jq -r '.Subnets | length ' | grep 0 && echo "no subnets found." &&
aws ec2 create-subnet --cidr-block 192.168.0.0/16 --vpc-id $VPC_ID --region $AWS_REGION
SUBNET_ID=$(aws ec2 describe-subnets --region $AWS_REGION | jq -r '.Subnets[0].SubnetId')

ROUTE_TABLE_ID=$( aws ec2 create-route-table --vpc-id $VPC_ID --region $AWS_REGION  | jq -r  'RouteTable.RouteTableId' )
echo "created the route table $ROUTE_TABLE_ID"

#modify it to support assigning an IPv4 IP
aws ec2 modify-subnet-attribute --map-public-ip-on-launch --subnet-id $SUBNET_ID --region $AWS_REGION

# might need to create a security group with everything in it and then assign that security group to the new instance?

aws ec2 run-instances --region $AWS_REGION --image-id $AMI_ID --count 1 --instance-type $INSTANCE_TYPE --key-name $KEYPAIR --user-data "$USER_DATA" --subnet $SUBNET_ID
