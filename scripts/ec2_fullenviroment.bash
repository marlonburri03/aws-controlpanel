#!/bin/bash

source "$(dirname "${BASH_SOURCE[0]}")/../lib/init_env.bash"

log "INFO" "Starting script: $(basename "$0")"

[[ -z "$VPC_NAME" ]] && read -p "Enter VPC name: " VPC_NAME
[[ -z "$VPC_CIDR" ]] && read -p "Enter VPC CIDR (e.g., 10.0.0.0/16): " VPC_CIDR
[[ -z "$PUBLIC_SUBNET_CIDR" ]] && read -p "Enter Public Subnet CIDR (e.g., 10.0.1.0/24): " PUBLIC_SUBNET_CIDR
#[[ -z "$AMI_ID" ]] && read -p "Enter AMI ID: " AMI_ID
#[[ -z "$INSTANCE_TYPE" ]] && read -p "Enter Instance Type (e.g., t2.micro): " INSTANCE_TYPE
#[[ -z "$KEY_NAME" ]] && read -p "Enter EC2 Key Pair Name: " KEY_NAME
#[[ -z "$USER_DATA_FILE" ]] && read -p "Enter path to User Data file: " USER_DATA_FILE
#[[ -z "$AWS_REGION" ]] && read -p "Enter AWS Region (e.g., us-east-1): " AWS_REGION

select_user_data_file() {
    echo "Verfügbare User Data Dateien:"
    ls "$ETCDIR"/*.yaml 2>/dev/null | xargs -n1 basename

    while true; do
        echo
        read -rp "Bitte gib den Namen der gewünschten User Data Datei ein (z. B. ubuntu_userdata.yaml): " user_data_file

        if [[ -f "${ETCDIR}/${user_data_file}" ]]; then
            echo "Datei gefunden: ${user_data_file}"
            USER_DATA_FILE="${ETCDIR}/${user_data_file}"
            break
        else
            echo "Datei nicht gefunden. Bitte erneut versuchen."
        fi
    done
}

get_latest_ami() {
    local owner=$1
    local name_filter=$2

    #log "DEBUG" "get newest AMI for $owner with filter $name_filter"
    aws ec2 describe-images \
        --owners "$owner" \
        --filters "Name=name,Values=$name_filter" "Name=state,Values=available" \
        --query 'Images | sort_by(@, &CreationDate)[-1].ImageId' \
        --output text
}

list_latest_amis() {
    #log "INFO" "List newest AMIs"
    echo "Newest AMI-IDs of the favourite Distributions:"
    amazon_ami=$(get_latest_ami amazon "amzn2-ami-hvm-2.0.*-x86_64-gp2")
    canonical_ami=$(get_latest_ami 099720109477 "ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*")
    redhat_ami=$(get_latest_ami 309956199498 "RHEL-8.*_HVM-*-x86_64-*")

    printf "Amazon Linux 2 (amazon): %s\n" "$amazon_ami"
    printf "Ubuntu 20.04 LTS (canonical): %s\n" "$canonical_ami"
    printf "Red Hat Enterprise Linux 8 (redhat): %s\n" "$redhat_ami"
    echo
}

read -p "Set EC2 instance name: " INSTANCE_NAME
[[ -z "$INSTANCE_NAME" ]] && { log "ERROR" "No name provided"; exit 1; }


AVAILABILITY_ZONE=$(aws ec2 describe-availability-zones \
  --region "$AWS_REGION" \
  --query "AvailabilityZones[0].ZoneName" \
  --output text)
log "INFO" "Using availability zone: $AVAILABILITY_ZONE"


create_vpc() {
  log "INFO" "Creating VPC..."
  VPC_ID=$(aws ec2 create-vpc \
    --cidr-block "$VPC_CIDR" \
    --region "$AWS_REGION" \
    --query "Vpc.VpcId" \
    --output text)
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

launch_ec2_instance() {
  log "INFO" "Launching EC2 instance..."
  INSTANCE_ID=$(aws ec2 run-instances \
    --image-id "$AMI_ID" \
    --instance-type "$INSTANCE_TYPE" \
    --key-name "$KEY_NAME" \
    --subnet-id "$SUBNET_ID" \
    --user-data "file://$USER_DATA_FILE" \
    --region "$AWS_REGION" \
    --associate-public-ip-address \
    --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$INSTANCE_NAME}]" \
    --query "Instances[0].InstanceId" \
    --output text)
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