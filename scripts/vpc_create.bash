#!/bin/bash
source "$(dirname "$0")/init_env.bash"

# Create a new VPC
create_vpc() {
    read -rp "Enter the VPC name: " vpc_name
    read -rp "Enter the IPv4 CIDR block (e.g., 10.0.0.0/16): " cidr_block
    read -rp "Enable IPv6 CIDR block? (y/n): " enable_ipv6
    read -rp "Enter the AWS region (e.g., eu-central-1): " region

    if [[ -z "$vpc_name" || -z "$cidr_block" || -z "$region" ]]; then
        echo "All fields are required."
        return 1
    fi

    echo "Creating VPC '$vpc_name' with CIDR block '$cidr_block' in region '$region'..."

    if [[ "$enable_ipv6" =~ ^[Yy]$ ]]; then
        vpc_id=$(aws ec2 create-vpc \
            --cidr-block "$cidr_block" \
            --amazon-provided-ipv6-cidr-block \
            --region "$region" \
            --query 'Vpc.VpcId' \
            --output text)
    else
        vpc_id=$(aws ec2 create-vpc \
            --cidr-block "$cidr_block" \
            --region "$region" \
            --query 'Vpc.VpcId' \
            --output text)
    fi

    if [[ -z "$vpc_id" ]]; then
        echo "Failed to create VPC."
        return 1
    fi

    aws ec2 create-tags \
        --resources "$vpc_id" \
        --tags Key=Name,Value="$vpc_name" \
        --region "$region"

    aws ec2 modify-vpc-attribute \
        --vpc-id "$vpc_id" \
        --enable-dns-support "{\"Value\":true}" \
        --region "$region"

    aws ec2 modify-vpc-attribute \
        --vpc-id "$vpc_id" \
        --enable-dns-hostnames "{\"Value\":true}" \
        --region "$region"

    echo "VPC '$vpc_name' created successfully with ID: $vpc_id"
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

# Call the function to create a VPC
create_vpc

# Pause for user input
read -rp "Press [Enter] to return to the VPC menu..."

# Return to VPC menu
source "$BINDIR/vpc_menu.bash"

# End of script
exit 0
