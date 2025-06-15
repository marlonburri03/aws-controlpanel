#!/bin/bash
source "$(dirname "${BASH_SOURCE[0]}")/../lib/init_env.bash"

log "INFO" "Starting Script: $(basename "$0")"

# Delete an existing Security Group
delete_security_group() {
    #read -rp "Enter the AWS region: " region

    #if [[ -z "$AWS_REGION" ]]; then
        #log "ERROR" "Region wurde nicht angegeben."
        #echo "Region is required."
        #return 1
    #fi

    #get security group
    echo "Fetching existing Security Groups in region '$AWS_REGION'..."
    aws ec2 describe-security-groups \
        --region "$AWS_REGION" \
        --query "SecurityGroups[*].{ID:GroupId,Name:GroupName,Description:Description,VPC:VpcId}" \
        --output table

    read -rp "Enter the Security Group ID to delete (e.g., sg-0abc1234def567890): " sg_id

    if [[ -z "$sg_id" ]]; then
        log "ERROR" "Security Group ID has not been set."
        echo "Security Group ID is required."
        return 1
    fi

    log "INFO" "Try to delete Security Group '$sg_id' in Region '$AWS_REGION'..."
    echo "Deleting Security Group '$sg_id'..."

    if aws ec2 delete-security-group --group-id "$sg_id" --region "$region"; then
        log "SUCCESS" "Security Group '$sg_id' deleted successfully."
        echo "Security Group '$sg_id' deleted successfully."
    else
        log "ERROR" "Error deleting the security group '$sg_id'. Possibly in use or incorrect ID."
        echo "Failed to delete Security Group. It might be in use or the ID is incorrect."
        return 1
    fi

    return 0
}

# run functions
check_aws_requirements
delete_security_group

# end of script