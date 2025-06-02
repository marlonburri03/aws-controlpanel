#!/bin/bash

# Create VPC and Subnet
create_vpc_and_subnet() {
    read -rp "Enter a CIDR block for the VPC (e.g., 10.0.0.0/16): " vpc_cidr
    read -rp "Enter a name for the VPC: " vpc_name
    read -rp "Enter a CIDR block for the Subnet (e.g., 10.0.1.0/24): " subnet_cidr
    read -rp "Enter a name for the Subnet: " subnet_name
    read -rp "Enter the Availability Zone (e.g., eu-central-1a): " az
    read -rp "Enter the AWS region: " region

    if [[ -z "$vpc_cidr" || -z "$vpc_name" || -z "$subnet_cidr" || -z "$subnet_name" || -z "$az" || -z "$region" ]]; then
        echo "All fields are required."
        return 1
    fi

    echo "Creating VPC '$vpc_name' with CIDR block '$vpc_cidr'..."

    vpc_id=$(aws ec2 create-vpc \
        --cidr-block "$vpc_cidr" \
        --region "$region" \
        --query "Vpc.VpcId" \
        --output text)

    if [[ -z "$vpc_id" ]]; then
        echo "Failed to create VPC."
        return 1
    fi

    aws ec2 create-tags \
        --resources "$vpc_id" \
        --tags Key=Name,Value="$vpc_name" \
        --region "$region"

    echo "VPC '$vpc_name' created with ID: $vpc_id"

    echo "Creating Subnet '$subnet_name' in VPC '$vpc_id'..."

    subnet_id=$(aws ec2 create-subnet \
        --vpc-id "$vpc_id" \
        --cidr-block "$subnet_cidr" \
        --availability-zone "$az" \
        --region "$region" \
        --query "Subnet.SubnetId" \
        --output text)

    if [[ -z "$subnet_id" ]]; then
        echo "Failed to create Subnet."
        return 1
    fi

    aws ec2 create-tags \
        --resources "$subnet_id" \
        --tags Key=Name,Value="$subnet_name" \
        --region "$region"

    aws ec2 modify-subnet-attribute \
        --subnet-id "$subnet_id" \
        --map-public-ip-on-launch \
        --region "$region"

    echo "Subnet '$subnet_name' created successfully with ID: $subnet_id"
    return 0
}

# Check if AWS CLI is installed
if ! command -v aws &> /dev/null; then
    echo "AWS CLI is not installed. Please install it first."
    exit 1
fi

# Check if user is authenticated
if ! aws sts get-caller-identity &> /dev/null; then
    echo "You are not authenticated with AWS. Please configure your credentials."
    exit 1
fi

# Call the function to create VPC and Subnet
create_vpc_and_subnet

# Pause for user input
read -rp "Press [Enter] to return to the Subnet menu..."

# Return to Subnet menu
source "$(dirname "$0")/subnet_menu.bash"

# End of script
exit 0
