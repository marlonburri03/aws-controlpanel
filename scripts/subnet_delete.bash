#!/bin/bash

# Delete a Subnet
delete_subnet() {
    echo "Fetching existing Subnets..."

    aws ec2 describe-subnets \
        --query "Subnets[*].{SubnetID:SubnetId, Name:Tags[?Key=='Name']|[0].Value, CIDR:CidrBlock, AZ:AvailabilityZone}" \
        --output table

    echo
    read -rp "Enter the Subnet ID to delete (e.g., subnet-0123abcd): " subnet_id
    read -rp "Enter the AWS region: " region

    if [[ -z "$subnet_id" || -z "$region" ]]; then
        echo "Subnet ID and region are required."
        return 1
    fi

    echo "Deleting Subnet '$subnet_id'..."

    aws ec2 delete-subnet \
        --subnet-id "$subnet_id" \
        --region "$region"

    if [[ $? -ne 0 ]]; then
        echo "Failed to delete Subnet '$subnet_id'."
        return 1
    fi

    echo "Subnet '$subnet_id' deleted successfully."
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

# Call the function to delete the Subnet
delete_subnet

# Pause for user input
read -rp "Press [Enter] to return to the Subnet menu..."

# Return to Subnet menu
source "$(dirname "$0")/subnet_menu.bash"

# End of script
exit 0
