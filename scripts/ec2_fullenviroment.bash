#!/bin/bash

source "$(dirname "${BASH_SOURCE[0]}")/../lib/init_env.bash"

log "INFO" "Starting script: $(basename "$0")"

[[ -z "$VPC_NAME" ]] && read -p "Enter VPC name: " VPC_NAME
[[ -z "$VPC_CIDR" ]] && read -p "Enter VPC CIDR (e.g., 10.0.0.0/16): " VPC_CIDR
[[ -z "$PUBLIC_SUBNET_CIDR" ]] && read -p "Enter Public Subnet CIDR (e.g., 10.0.1.0/24): " PUBLIC_SUBNET_CIDR

create_vpc() {
  log "INFO" "Creating VPC..."
  VPC_ID=$(aws ec2 create-vpc \
    --cidr-block "$VPC_CIDR" \
    --region "$AWS_REGION" \
    --query "Vpc.VpcId" \
    --output text)
  # Tags richtig quoten, hier explizit in Anführungszeichen
  aws ec2 create-tags --resources "$VPC_ID" --tags Key=Name,Value="$VPC_NAME" --region "$AWS_REGION"
  log "INFO" "VPC created: $VPC_ID"
}

create_subnet() {
  log "INFO" "Creating subnet..."
  SUBNET_ID=$(aws ec2 create-subnet \
    --vpc-id "$VPC_ID" \
    --cidr-block "$PUBLIC_SUBNET_CIDR" \
    --availability-zone "$AVAILABILITY_ZONE" \
    --region "$AWS_REGION" \
    --query "Subnet.SubnetId" \
    --output text)
  aws ec2 create-tags --resources "$SUBNET_ID" --tags Key=Name,Value="${VPC_NAME}-public-subnet" --region "$AWS_REGION"
  log "INFO" "Subnet created: $SUBNET_ID"
}

create_internet_gateway() {
  log "INFO" "Creating and attaching Internet Gateway..."
  IGW_ID=$(aws ec2 create-internet-gateway \
    --region "$AWS_REGION" \
    --query "InternetGateway.InternetGatewayId" \
    --output text)
  aws ec2 attach-internet-gateway --vpc-id "$VPC_ID" --internet-gateway-id "$IGW_ID" --region "$AWS_REGION"
  aws ec2 create-tags --resources "$IGW_ID" --tags Key=Name,Value="${VPC_NAME}-igw" --region "$AWS_REGION"
  log "INFO" "Internet Gateway created and attached: $IGW_ID"
}

create_route_table() {
  log "INFO" "Creating Route Table and associating it with subnet..."
  RT_ID=$(aws ec2 create-route-table \
    --vpc-id "$VPC_ID" \
    --region "$AWS_REGION" \
    --query "RouteTable.RouteTableId" \
    --output text)
  aws ec2 create-tags --resources "$RT_ID" --tags Key=Name,Value="${VPC_NAME}-rt" --region "$AWS_REGION"
  aws ec2 create-route --route-table-id "$RT_ID" --destination-cidr-block 0.0.0.0/0 --gateway-id "$IGW_ID" --region "$AWS_REGION"
  aws ec2 associate-route-table --subnet-id "$SUBNET_ID" --route-table-id "$RT_ID" --region "$AWS_REGION"
  log "INFO" "Route Table created and associated: $RT_ID"
}

select_user_data_file() {
  echo "Available User Data files:"
  echo "1) Template_Linux_Webserver.yaml"
  echo "2) Template_Ubuntu.yaml"
  echo "3) Template_Ubuntu_Docker.yaml"

  while true; do
    read -p "Please enter the number of the desired User Data file (1-3): " choice
    case $choice in
      1) file="Template_Linux_Webserver.yaml"; break ;;
      2) file="Template_Ubuntu.yaml"; break ;;
      3) file="Template_Ubuntu_Docker.yaml"; break ;;
      *) echo "Invalid input. Please enter 1, 2, or 3." ;;
    esac
  done
    USER_DATA_FILE="$ETCDIR/$file"
  echo "You selected: $USER_DATA_FILE"
}

launch_ec2_instance() {
  log "INFO" "Launching EC2 instance..."


# get user data file
  if [[ "$USER_DATA_FILE" =~ ^[a-zA-Z]:\\ ]]; then
  
    USER_DATA_FILE=$(echo "$USER_DATA_FILE" | sed -E 's#^([a-zA-Z]):\\#\/mnt\/\L\1\/#' | tr '\\' '/')
  fi

  aws ec2 run-instances \
    --image-id "$AMI_ID" \
    --instance-type "$INSTANCE_TYPE" \
    --key-name "$KEY_NAME" \
    --subnet-id "$SUBNET_ID" \
    --user-data "file://$USER_DATA_FILE" \
    --region "$AWS_REGION" \
    --associate-public-ip-address \
    --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=\"$INSTANCE_NAME\"}]" \
    --query "Instances[0].InstanceId" \
    --output text | tee >(read INSTANCE_ID)
  
  if [[ -z "$INSTANCE_ID" ]]; then
    log "ERROR" "Failed to launch EC2 instance"
    exit 1
  fi

  log "INFO" "EC2 Instance launched: $INSTANCE_ID"
}


# run functions
check_aws_requirements
create_vpc
create_subnet
create_internet_gateway
create_route_table
select_user_data_file
launch_ec2_instance

log "SUCCESS" "Fertig! EC2-Instanz '$INSTANCE_NAME' wurde erstellt."

# end of script