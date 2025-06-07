#!/bin/bash

source "$(dirname "${BASH_SOURCE[0]}")/../lib/init_env.bash"

log "INFO" "Starte Script: $(basename "$0")"

VPC_NAME="vpc-advanced"

# Advanced VPC-Configuration
VPC_CIDR="10.0.5.0/24"
PUBLIC_SUBNET_CIDR_1="10.0.5.0/26"
PUBLIC_SUBNET_CIDR_2="10.0.5.64/26"
PRIVATE_SUBNET_CIDR_1="10.0.5.128/26"
PRIVATE_SUBNET_CIDR_2="10.0.5.192/26"

# Get instance name
INSTANCE_NAME="$1"
if [[ -z "$INSTANCE_NAME" ]]; then
    read -p "Set instance name: " INSTANCE_NAME
fi

if [[ -z "$INSTANCE_NAME" ]]; then
    log "ERROR" "No name has been set!"
    exit 1
fi

# get cloud-init
if [[ ! -f "$USER_DATA_FILE" ]]; then
    log "ERROR" "File not found: $USER_DATA_FILE"
    exit 1
fi  

USER_DATA=$(<"$USER_DATA_FILE")

# create VPC
log "INFO" "Create VPC..."
VPC_ID=$(aws ec2 create-vpc --region "$AWS_REGION" --cidr-block "$VPC_CIDR" --query 'Vpc.VpcId' --output text 2>>"$LOGFILE")
if [[ $? -ne 0 ]]; then
    log "ERROR" "Failed to create VPC."
    exit 1
fi
log "SUCCESS" "VPC created: ${blue}$VPC_ID${reset}"
aws ec2 modify-vpc-attribute --vpc-id "$VPC_ID" --enable-dns-hostnames "{\"Value\":true}"

# Add Name Tag to VPC
aws ec2 create-tags --region "$AWS_REGION" --resources "$VPC_ID" --tags Key=Name,Value="$VPC_NAME"
log "SUCCESS" "VPC named: ${blue}$VPC_NAME${reset}"

# create internet gateway
log "INFO" "Create Internet Gateway..."
IGW_ID=$(aws ec2 create-internet-gateway --region "$AWS_REGION" --query 'InternetGateway.InternetGatewayId' --output text 2>>"$LOGFILE")
aws ec2 attach-internet-gateway --region "$AWS_REGION" --internet-gateway-id "$IGW_ID" --vpc-id "$VPC_ID"
log "SUCCESS" "Internet Gateway created: ${blue}$IGW_ID${reset}"

# create subnets

log "INFO" "Create Subnets..."
PUBLIC_SUBNET_1=$(aws ec2 create-subnet --region "$AWS_REGION" --vpc-id "$VPC_ID" --cidr-block "$PUBLIC_SUBNET_CIDR_1" --availability-zone "$AZ1" --query 'Subnet.SubnetId' --output text 2>>"$LOGFILE")
PUBLIC_SUBNET_2=$(aws ec2 create-subnet --region "$AWS_REGION" --vpc-id "$VPC_ID" --cidr-block "$PUBLIC_SUBNET_CIDR_2" --availability-zone "$AZ2" --query 'Subnet.SubnetId' --output text 2>>"$LOGFILE")
PRIVATE_SUBNET_1=$(aws ec2 create-subnet --region "$AWS_REGION" --vpc-id "$VPC_ID" --cidr-block "$PRIVATE_SUBNET_CIDR_1" --availability-zone "$AZ1" --query 'Subnet.SubnetId' --output text 2>>"$LOGFILE")
PRIVATE_SUBNET_2=$(aws ec2 create-subnet --region "$AWS_REGION" --vpc-id "$VPC_ID" --cidr-block "$PRIVATE_SUBNET_CIDR_2" --availability-zone "$AZ2" --query 'Subnet.SubnetId' --output text 2>>"$LOGFILE")
log "SUCCESS" "Subnets created: Public: ${blue}$PUBLIC_SUBNET_1${reset}, ${blue}$PUBLIC_SUBNET_2${reset} | Private: ${blue}$PRIVATE_SUBNET_1${reset}, ${blue}$PRIVATE_SUBNET_2${reset}"

# enable public IP assignment for public subnets
log "INFO" "Enable automatic IP assignment for public subnets..."
aws ec2 modify-subnet-attribute --region "$AWS_REGION" --subnet-id "$PUBLIC_SUBNET_1" --map-public-ip-on-launch
if [[ $? -ne 0 ]]; then
    log "ERROR" "Failed to activate public IP assignment for ${red}$PUBLIC_SUBNET_1${reset}."
else
    log "SUCCESS" "Public IP assignment activated for ${blue}$PUBLIC_SUBNET_1${reset}."
fi

aws ec2 modify-subnet-attribute --region "$AWS_REGION" --subnet-id "$PUBLIC_SUBNET_2" --map-public-ip-on-launch
if [[ $? -ne 0 ]]; then
    log "ERROR" "Failed to activate public IP assignment for ${red}$PUBLIC_SUBNET_2${reset}."
else
    log "SUCCESS" "Public IP assignment activated for ${blue}$PUBLIC_SUBNET_2${reset}."
fi

log "SUCCESS" "Automatic assignment for public IP activated."

# assign route table for public IPs
log "INFO" "Create route table for public subnets..."
ROUTE_TABLE_ID=$(aws ec2 create-route-table --region "$AWS_REGION" --vpc-id "$VPC_ID" --query 'RouteTable.RouteTableId' --output text 2>>"$LOGFILE")
aws ec2 create-route --region "$AWS_REGION" --route-table-id "$ROUTE_TABLE_ID" --destination-cidr-block "0.0.0.0/0" --gateway-id "$IGW_ID" > /dev/null 2>>"$LOGFILE"
aws ec2 associate-route-table --region "$AWS_REGION" --route-table-id "$ROUTE_TABLE_ID" --subnet-id "$PUBLIC_SUBNET_1" > /dev/null 2>>"$LOGFILE"
aws ec2 associate-route-table --region "$AWS_REGION" --route-table-id "$ROUTE_TABLE_ID" --subnet-id "$PUBLIC_SUBNET_2" > /dev/null 2>>"$LOGFILE"
log "SUCCESS" "Route table created: ${blue}$ROUTE_TABLE_ID${reset}"

# create security group
log "INFO" "Erstelle Security Group..."
SG_PUBLIC=$(aws ec2 create-security-group --region "$AWS_REGION" --group-name "Public-SSH-HTTP-SG" --description "Public SSH and HTTP access" --vpc-id "$VPC_ID" --query 'GroupId' --output text 2>>"$LOGFILE")
aws ec2 authorize-security-group-ingress --region "$AWS_REGION" --group-id "$SG_PUBLIC" --protocol tcp --port 22 --cidr 0.0.0.0/0 > /dev/null 2>>"$LOGFILE"
aws ec2 authorize-security-group-ingress --region "$AWS_REGION" --group-id "$SG_PUBLIC" --protocol tcp --port 80 --cidr 0.0.0.0/0 > /dev/null 2>>"$LOGFILE"
log "SUCCESS" "Security Group erstellt: ${blue}$SG_PUBLIC${reset}"

# start EC2-Instance
log "INFO" "Start EC2-Instance..."
INSTANCE_ID=$(aws ec2 run-instances --region "$AWS_REGION" --image-id "$AMI_ID" --instance-type "$INSTANCE_TYPE" --key-name "$KEY_NAME" --security-group-ids "$SG_PUBLIC" --subnet-id "$PUBLIC_SUBNET_1" --user-data "$USER_DATA" --query 'Instances[0].InstanceId' --output text 2>>"$LOGFILE")
log "SUCCESS" "Instance created: ${blue}$INSTANCE_ID${reset}"
aws ec2 create-tags --region "$AWS_REGION" --resources "$INSTANCE_ID" --tags Key=Name,Value="$INSTANCE_NAME"

# waiter
log "INFO" "Wait until instance is running..."
aws ec2 wait instance-running --region "$AWS_REGION" --instance-ids "$INSTANCE_ID"

# get public IP
PUBLIC_IP=$(aws ec2 describe-instances --region "$AWS_REGION" --instance-ids "$INSTANCE_ID" --query 'Reservations[0].Instances[0].PublicIpAddress' --output text 2>>"$LOGFILE")

if [ "$PUBLIC_IP" == "None" ]; then
    log "WARNING" "No public IP for the Instance available."
else
    log "SUCCESS" "Instance running. Public IP-Adresse: ${blue}$PUBLIC_IP${reset}"
    log "INFO" "To connect with SSH use: ${blue}ssh -i id_rsa_burri ubuntu@$PUBLIC_IP${reset}"
fi

# get Ressource Summary
Summary=(
    "VPC ID: ${blue}$VPC_ID${reset}"
    "Public Subnet 1: ${blue}$PUBLIC_SUBNET_1${reset}"
    "Public Subnet 2: ${blue}$PUBLIC_SUBNET_2${reset}"
    "Private Subnet 1: ${blue}$PRIVATE_SUBNET_1${reset}"
    "Private Subnet 2: ${blue}$PRIVATE_SUBNET_2${reset}"
    "Internet Gateway: ${blue}$IGW_ID${reset}"
    "Route Table: ${blue}$ROUTE_TABLE_ID${reset}"
    "Security Group: ${blue}$SG_PUBLIC${reset}"
    "Instance Name: ${blue}$INSTANCE_NAME${reset}"
    "Instance ID: ${blue}$INSTANCE_ID${reset}"
    "Public IP: ${blue}$PUBLIC_IP${reset}"
)

log "INFO" "Summary of the created ressources:"
for item in "${Summary[@]}"; do
    log "INFO" "$item"
done

log "INFO" "Deployment completed."
