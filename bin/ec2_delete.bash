#!/bin/bash

# Delete EC2 instance
delete_ec2_instance() {
    read -rp "Enter the Instance ID to delete: " instance_id
    if [[ -z "$instance_id" ]]; then
        echo "Instance ID cannot be empty."
        return 1
    fi
    echo "Deleting EC2 instance with ID: $instance_id..."
    aws ec2 terminate-instances --instance-ids "$instance_id"
    if [[ $? -ne 0 ]]; then
        echo "Failed to delete instance $instance_id."
        return 1
    fi
    echo "Instance $instance_id has been deleted successfully."
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
# Call the function to delete instance
delete_ec2_instance
# Pause for user input
read -rp "Press [Enter] to return to the EC2 menu..."
# Return to EC2 menu
source "$(dirname "$0")/ec2_menu.bash"
# End of script
# Exit the script
exit 0