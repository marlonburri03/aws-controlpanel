#!/bin/bash
source "$(dirname "${BASH_SOURCE[0]}")/../lib/init_env.bash"

log "INFO" "Starting Script: $(basename "$0")"

# delete Subnet
delete_subnet() {
    echo "Fetching existing Subnets..."

    aws ec2 describe-subnets \
        --query "Subnets[*].{SubnetID:SubnetId, Name:Tags[?Key=='Name']|[0].Value, CIDR:CidrBlock, AZ:AvailabilityZone}" \
        --output table

    echo
    read -rp "Enter the Subnet ID to delete (e.g., subnet-0123abcd): " subnet_id
    #read -rp "Enter the AWS region: " region

    if [[ -z "$subnet_id" || -z "$AWS_REGION" ]]; then
        echo "Subnet ID and region are required."
        return 1
    fi

    echo "Deleting Subnet '$subnet_id'..."

    aws ec2 delete-subnet \
        --subnet-id "$subnet_id" \
        --region "$AWS_REGION"

    if [[ $? -ne 0 ]]; then
        echo "Failed to delete Subnet '$subnet_id'."
        return 1
    fi

    echo "Subnet '$subnet_id' deleted successfully."
    return 0
}

# run functions
check_aws_requirements
delete_subnet

# end of script