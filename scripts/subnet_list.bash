#!/bin/bash
source "$(dirname "${BASH_SOURCE[0]}")/../lib/init_env.bash"

log "INFO" "Starting Script: $(basename "$0")"

# list subnets
list_subnets() {
    #read -rp "Enter the AWS region: " region

    #if [[ -z "$region" ]]; then
        #echo "Region is required."
        #return 1
    #fi

    echo "Fetching Subnets in region '$AWS_REGION'..."

    aws ec2 describe-subnets \
        --region "$AWS_REGION" \
        --query "Subnets[*].{SubnetID:SubnetId, VPC:VpcId, CIDR:CidrBlock, AZ:AvailabilityZone, Name:Tags[?Key=='Name']|[0].Value}" \
        --output table

    if [[ $? -ne 0 ]]; then
        echo "Failed to retrieve Subnets."
        return 1
    fi

    echo "Subnets listed successfully."
    return 0
}

# run functions
check_aws_requirements
list_subnets

# end of script