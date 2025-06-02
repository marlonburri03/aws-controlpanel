#!/bin/bash
source "$(dirname "$0")/init_env.bash"

# List all VPCs
list_vpcs() {
    read -rp "Enter the AWS region (e.g., eu-central-1): " region

    if [[ -z "$region" ]]; then
        echo "Region cannot be empty."
        return 1
    fi

    echo "Listing VPCs in region '$region'..."
    aws ec2 describe-vpcs \
        --region "$region" \
        --query "Vpcs[*].{ID:VpcId,Name:Tags[?Key=='Name']|[0].Value,CIDR:CidrBlock,State:State}" \
        --output table
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

# Call the function to list VPCs
list_vpcs

# Pause for user input
read -rp "Press [Enter] to return to the VPC menu..."

# Return to VPC menu
source "$(dirname "$0")/vpc_menu.bash"

# End of script
exit 0
