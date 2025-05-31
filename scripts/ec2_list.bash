#!/bin/bash

# List EC2 instances

list_ec2_instances() {
    echo "Listing EC2 instances..."
    aws ec2 describe-instances \
        --query 'Reservations[*].Instances[*].[InstanceId,State.Name,PublicIpAddress,Tags[?Key==`Name`].Value | [0]]' \
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
# Call the function to list instances
list_ec2_instances
# Pause for user input
read -rp "Press [Enter] to return to the EC2 menu..."
# Return to EC2 menu
source "$(dirname "$0")/ec2_menu.bash"
# End of script
# Exit the script
exit 0