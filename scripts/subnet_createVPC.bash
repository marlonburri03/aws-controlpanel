#!/bin/bash
source "$(dirname "${BASH_SOURCE[0]}")/../lib/init_env.bash"

log "INFO" "Starting Script: $(basename "$0")"

# create VPC and Subnet
create_vpc_and_subnet() {
    read -rp "Enter a CIDR block for the VPC (e.g., 10.0.0.0/16): " vpc_cidr
    read -rp "Enter a name for the VPC: " vpc_name
    read -rp "Enter a CIDR block for the Subnet (e.g., 10.0.1.0/24): " subnet_cidr
    read -rp "Enter a name for the Subnet: " subnet_name
    read -rp "Enter the Availability Zone (e.g., eu-central-1a): " az
    #read -rp "Enter the AWS region: " region

    if [[ -z "$vpc_cidr" || -z "$vpc_name" || -z "$subnet_cidr" || -z "$subnet_name" || -z "$az" || -z "$AWS_REGION" ]]; then
        echo "All fields are required."
        return 1
    fi

    echo "Creating VPC '$vpc_name' with CIDR block '$vpc_cidr'..."

    vpc_id=$(aws ec2 create-vpc \
        --cidr-block "$vpc_cidr" \
        --region "$AWS_REGION" \
        --query "Vpc.VpcId" \
        --output text)

    if [[ -z "$vpc_id" ]]; then
        echo "Failed to create VPC."
        return 1
    fi

    aws ec2 create-tags \
        --resources "$vpc_id" \
        --tags Key=Name,Value="$vpc_name" \
        --region "$AWS_REGION"

    echo "VPC '$vpc_name' created with ID: $vpc_id"

    echo "Creating Subnet '$subnet_name' in VPC '$vpc_id'..."

    subnet_id=$(aws ec2 create-subnet \
        --vpc-id "$vpc_id" \
        --cidr-block "$subnet_cidr" \
        --availability-zone "$az" \
        --region "$AWS_REGION" \
        --query "Subnet.SubnetId" \
        --output text)

    if [[ -z "$subnet_id" ]]; then
        echo "Failed to create Subnet."
        return 1
    fi

    aws ec2 create-tags \
        --resources "$subnet_id" \
        --tags Key=Name,Value="$subnet_name" \
        --region "$AWS_REGION"

    aws ec2 modify-subnet-attribute \
        --subnet-id "$subnet_id" \
        --map-public-ip-on-launch \
        --region "$AWS_REGION"

    echo "Subnet '$subnet_name' created successfully with ID: $subnet_id"
    return 0
}

# run functions
check_aws_requirements
create_vpc_and_subnet

# end of script