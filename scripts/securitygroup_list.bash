#!/bin/bash

# List existing Security Groups
list_security_groups() {
    read -rp "Enter the AWS region: " region

    if [[ -z "$region" ]]; then
        echo "Region is required."
        return 1
    fi

    echo "Fetching Security Groups in region '$region'..."

    aws ec2 describe-security-groups \
        --region "$region" \
        --query "SecurityGroups[*].{ID:GroupId,Name:GroupName,Description:Description,VPC:VpcId}" \
        --output table
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

# Call the function to list Security Groups
list_security_groups

# Pause for user input
read -rp "Press [Enter] to return to the Network menu..."

# Return to the menu (adjust path if needed)
source "$(dirname "$0")/securitygroup_menu.bash"

# End of script
exit 0
