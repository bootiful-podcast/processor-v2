#!/bin/bash

#####
export BP_MODE="development"
if [ "$GITHUB_EVENT_NAME" = "create" ]; then
  if [[ "${GITHUB_REF}" =~ "tags" ]]; then
    BP_MODE="production"
  fi
fi

echo "BP_MODE=${BP_MODE}"

AWS_REGION_development=us-west-2
AWS_REGION_production=us-east-1

AMI_ID_development=ami-0d6621c01e8c2de2c
AMI_ID_production=ami-0323c3dd2da7fb37d

VARIABLE_NAMES=(PODCAST_RMQ_ADDRESS AMI_ID AWS_REGION)
for V in ${VARIABLE_NAMES[*]}; do
  TO_EVAL="export ${V}=\$${V}_${BP_MODE}"
  echo $TO_EVAL
  eval $TO_EVAL
done

###
### Userdata
KEYPAIR_FILE=$HOME/${KEYPAIR_NAME}.pem
USER_DATA=$(python3 build-user-data-bootstrap.py $GITHUB_SHA $PODCAST_RMQ_ADDRESS $BP_MODE)
echo "$USER_DATA"

### RESET
### terminate all existing instances
aws ec2 describe-instances --filter Name=tag:github_repository,Values="$GITHUB_REPOSITORY" Name=instance-state-name,Values=running --region $AWS_REGION | jq -r ".Reservations[].Instances[].InstanceId" | while read IID; do
  echo "terminating ${IID}."
  aws ec2 terminate-instances --instance-ids $IID --region $AWS_REGION
done

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

SG_ID=$(aws ec2 describe-security-groups --region $AWS_REGION | jq -r "$(python3 build-jq-query.py $SECURITY_GROUP_NAME)")
echo "SG_ID=$SG_ID"

### Keypair
if [ "$(aws ec2 describe-key-pairs --region $AWS_REGION | jq -r '.KeyPairs[].KeyName ' | grep $KEYPAIR_NAME)" = "" ]; then
  ls -la $KEYPAIR_FILE && rm -rf $KEYPAIR_FILE
  aws ec2 create-key-pair --region $AWS_REGION --key-name $KEYPAIR_NAME --query 'KeyMaterial' --output text >$KEYPAIR_FILE
  chmod 400 $KEYPAIR_FILE
fi

## Run the instance on EC2
IMAGE_NAME=$AMI_ID #todo can we fix this later? it'd be nice to query for the image and get the latest and greatest, i guess.

### todo: it would be nice to find a way to query for the tags of any instances, see if they have the same github repository, and if so - terminate them.
INSTANCE_ID=$(aws ec2 run-instances  --iam-instance-profile Name=bootiful-podcast-processor --user-data "$USER_DATA" --region $AWS_REGION --image-id $IMAGE_NAME --count 1 --instance-type $INSTANCE_TYPE --key-name $KEYPAIR_NAME --security-group-ids $SG_ID --subnet-id $SUBNET_ID --tag-specifications "$(python3 build-github-resource-tags.py $GITHUB_REPOSITORY $GITHUB_SHA)" --associate-public-ip-address | jq -r '.Instances[0].InstanceId')
echo "INSTANCE_ID=$INSTANCE_ID"

aws ec2 create-tags --resources $INSTANCE_ID --tags Key=github_repository,Value="$GITHUB_REPOSITORY"
aws ec2 create-tags --resources $INSTANCE_ID --tags Key=github_sha,Value="$GITHUB_SHA"

DNS_NAME=""

resolve_dns() {
  aws ec2 describe-instances --region $AWS_REGION --instance-ids $INSTANCE_ID | jq -r '.Reservations[0].Instances[0].PublicDnsName'
}

DNS_NAME="$(resolve_dns)"
while [ "${DNS_NAME}" = "" ]; do
  sleep 1
  DNS_NAME="$(resolve_dns)"
done

echo "DNS_NAME=$DNS_NAME"
echo "Deploy finished"

#ssh -i $KEYPAIR_FILE ec2-user@${DNS_NAME}
