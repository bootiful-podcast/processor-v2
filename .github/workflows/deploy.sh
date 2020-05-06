#!/bin/sh
AMI_ID=ami-0d6621c01e8c2de2c
AWS_REGION=us-west-2
INSTANCE_TYPE=t3.large
SUBNET_ID=subnet-05ec18a303fb18a5c
SECURITY_GROUP_NAME=bootiful-podcast-sg
USER_DATA_URL=https://raw.githubusercontent.com/bootiful-podcast/python-test-to-deploy/master/.github/workflows/bootstrap.sh
USER_DATA=$(python3 ./build-user-data-bootstrap.py $USER_DATA_URL $PODCAST_RMQ_ADDRESS) # todo: we need some sort of program to in turn encode the current github version into the built-and-baked app
KEYPAIR_NAME=bootiful-podcast
KEYPAIR_FILE=$HOME/${KEYPAIR_NAME}.pem

## TODO: go through and terminate all running apps on script start.

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
#SG_ID=$(aws ec2 describe-security-groups --region $AWS_REGION | jq -r ' .[] | map(select (.GroupName == "bootiful-podcast-sg") ) | .[0].GroupId ')
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
INSTANCE_ID=$(aws ec2 run-instances --user-data "$USER_DATA" --region $AWS_REGION --image-id $IMAGE_NAME --count 1 --instance-type $INSTANCE_TYPE --key-name $KEYPAIR_NAME --security-group-ids $SG_ID --subnet-id $SUBNET_ID --tag-specifications "$(python3 build-github-resource-tags.py $GITHUB_REPOSITORY $GITHUB_SHA)" --associate-public-ip-address | jq -r '.Instances[0].InstanceId')
echo "INSTANCE_ID=$INSTANCE_ID"

#aws ec2 create-tags --resources $INSTANCE_ID --tags Key=github_repository,Value="$GITHUB_REPOSITORY"
#aws ec2 create-tags --resources $INSTANCE_ID --tags Key=github_sha,Value="$GITHUB_SHA"

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

#ssh -i $KEYPAIR_FILE ec2-user@${DNS_NAME}
