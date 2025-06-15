#!/bin/bash
source "$(dirname "${BASH_SOURCE[0]}")/../lib/init_env.bash"

log "INFO" "Starting Script: $(basename "$0")"

# list existing Security Groups
list_security_groups() {
    #read -rp "Enter the AWS region: " region

    #if [[ -z "$region" ]]; then
        #log "ERROR" "Region was not specified."
        #echo "Region is required."
        #return 1
    #fi

    #get security group
    echo "Fetching Security Groups in region '$AWS_REGION'..."

    aws ec2 describe-security-groups \
        --region "$region" \
        --query "SecurityGroups[*].{ID:GroupId,Name:GroupName,Description:Description,VPC:VpcId}" \
        --output table
}

# run functions
check_aws_requirements
list_security_groups

# end of script