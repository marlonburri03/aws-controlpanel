#!/bin/bash

# default region for aws cli calls
AWS_REGION="us-east-1"

# default availability zones for subnets
#AZ1="${AWS_REGION}a"
#AZ2="${AWS_REGION}b"

# ami and instance configuration
#AMI_ID="ami-0e2c8caa4b6378d8c"
INSTANCE_TYPE="t2.micro"

# ssh key pair for ec2 instances
KEY_NAME="vockey"

# cloud-init file used as user data
USER_DATA_FILE="$CONFDIR/"