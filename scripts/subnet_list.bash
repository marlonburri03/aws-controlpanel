#!/bin/bash
source "$(dirname "${BASH_SOURCE[0]}")/../lib/init_env.bash"

# List existing Subnets
list_subnets() {
    read -rp "Enter the AWS region: " region

    if [[ -z "$region" ]]; then
        echo "Region is required."
        return 1
    fi

    echo "Fetching Subnets in region '$region'..."

    aws ec2 describe-subnets \
        --region "$region" \
        --query "Subnets[*].{SubnetID:SubnetId, VPC:VpcId, CIDR:CidrBlock, AZ:AvailabilityZone, Name:Tags[?Key=='Name']|[0].Value}" \
        --output table

    if [[ $? -ne 0 ]]; then
        echo "Failed to retrieve Subnets."
        return 1
    fi

    echo "Subnets listed successfully."
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

# Call the function to list the Subnets
list_subnets

# Pause for user input
read -rp "Press [Enter] to return to the Subnet menu..."

# Return to Subnet menu
source "$(dirname "$0")/subnet_menu.bash"

# End of script
exit 0
