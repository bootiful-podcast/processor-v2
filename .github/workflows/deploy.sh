#!/bin/bash

#
# var urlResource = new UrlResource("https://raw.githubusercontent.com/bootiful-podcast/processor-installer/master/assets/bootstrap.sh");
# var keypair = "bootiful-podcast_processor_05-02-2020";
# var securityGroup = "web-host";
# var amazonImageId = "ami-06fcc1f0bc2c8943f";
# var region = "us-west-1"

aws ec2 run-instances --image-id ami-xxxxxxxx --count 1 --instance-type t2.micro --key-name MyKeyPair --security-group-ids sg-903004f8 --subnet-id subnet-6e7f829e
