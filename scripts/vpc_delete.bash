#!/bin/bash
source "$(dirname "${BASH_SOURCE[0]}")/../lib/init_env.bash"

# Delete a VPC
delete_vpc() {
    read -rp "Enter the VPC ID to delete (e.g., vpc-123abc456def): " vpc_id
    read -rp "Enter the AWS region of the VPC: " region

    if [[ -z "$vpc_id" || -z "$region" ]]; then
        echo "VPC ID and region are required."
        return 1
    fi

    echo "WARNING: Deleting a VPC will also remove all associated resources (subnets, gateways, etc.)."
    read -rp "Are you sure you want to delete VPC '$vpc_id'? (y/N): " confirm
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        echo "Aborted."
        return 0
    fi

    echo "Deleting VPC '$vpc_id'..."
    aws ec2 delete-vpc --vpc-id "$vpc_id" --region "$region"

    if [[ $? -ne 0 ]]; then
        echo "Failed to delete VPC $vpc_id."
        return 1
    fi

    echo "VPC $vpc_id deleted successfully."
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

# Call the function to delete the VPC
delete_vpc

# Pause for user input
read -rp "Press [Enter] to return to the VPC menu..."

# Return to VPC menu
source "$(dirname "$0")/vpc_menu.bash"

# End of script
exit 0
