#!/bin/bash
source "$(dirname "${BASH_SOURCE[0]}")/../lib/init_env.bash"

log "INFO" "Starting Script: $(basename "$0")"

# List all VPCs
list_vpcs() {
    #read -rp "Enter the AWS region (e.g., eu-central-1): " region

    if [[ -z "$AWS_REGION" ]]; then
        echo "Region cannot be empty."
        return 1
    fi

    echo "Listing VPCs in region '$AWS_REGION'..."
    aws ec2 describe-vpcs \
        --region "$AWS_REGION" \
        --query "Vpcs[*].{ID:VpcId,Name:Tags[?Key=='Name']|[0].Value,CIDR:CidrBlock,State:State}" \
        --output table
    return 0
}

# run functions
check_aws_requirements
list_vpcs

# end of script