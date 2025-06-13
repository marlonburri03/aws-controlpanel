#!/bin/bash
source "$(dirname "${BASH_SOURCE[0]}")/../lib/init_env.bash"

log "INFO" "Starting Script: $(basename "$0")"

# main function
create_vpc() {
    read -rp "Enter the VPC name: " vpc_name
    read -rp "Enter the IPv4 CIDR block (e.g., 10.0.0.0/16): " cidr_block
    read -rp "Enable IPv6 CIDR block? (y/n): " enable_ipv6
    #read -rp "Enter the AWS region (e.g., eu-central-1): " region

    if [[ -z "$vpc_name" || -z "$cidr_block" || -z "$AWS_REGION" ]]; then
        echo "All fields are required."
        return 1
    fi

    echo "Creating VPC '$vpc_name' with CIDR block '$cidr_block' in region '$AWS_REGION'..."

    if [[ "$enable_ipv6" =~ ^[Yy]$ ]]; then
        vpc_id=$(aws ec2 create-vpc \
            --cidr-block "$cidr_block" \
            --amazon-provided-ipv6-cidr-block \
            --region "$AWS_REGION" \
            --query 'Vpc.VpcId' \
            --output text)
    else
        vpc_id=$(aws ec2 create-vpc \
            --cidr-block "$cidr_block" \
            --region "$AWS_REGION" \
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
        --region "$AWS_REGION"

    aws ec2 modify-vpc-attribute \
        --vpc-id "$vpc_id" \
        --enable-dns-support "{\"Value\":true}" \
        --region "$AWS_REGION"

    aws ec2 modify-vpc-attribute \
        --vpc-id "$vpc_id" \
        --enable-dns-hostnames "{\"Value\":true}" \
        --region "$AWS_REGION"

    echo "VPC '$vpc_name' created successfully with ID: $vpc_id"
    return 0
}

# run functions
check_aws_requirements
create_vpc

# end of script