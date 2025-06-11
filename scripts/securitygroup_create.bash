#!/bin/bash
source "$(dirname "${BASH_SOURCE[0]}")/../lib/init_env.bash"

log "INFO" "Starting Script: $(basename "$0")"

# Create a new Security Group with standard Linux rules
create_security_group() {
    read -rp "Enter the VPC ID where the Security Group will be created (e.g., vpc-123abc456def): " vpc_id
    read -rp "Enter a name for the Security Group: " sg_name
    read -rp "Enter a description for the Security Group: " sg_description
    read -rp "Enter the AWS region: " region

    if [[ -z "$vpc_id" || -z "$sg_name" || -z "$sg_description" || -z "$region" ]]; then
        log "ERROR" "One or more required fields are empty."
        echo "All fields are required."
        return 1
    fi

    log "INFO" "Creating Security Group '$sg_name' in VPC '$vpc_id' in region '$region'..."
    echo "Creating Security Group '$sg_name' in VPC '$vpc_id'..."

    sg_id=$(aws ec2 create-security-group \
        --group-name "$sg_name" \
        --description "$sg_description" \
        --vpc-id "$vpc_id" \
        --region "$region" \
        --query "GroupId" \
        --output text 2>>"$LOGFILE")

    if [[ -z "$sg_id" ]]; then
        log "ERROR" "Failed to create Security Group '$sg_name'."
        echo "Failed to create Security Group."
        return 1
    fi

    log "SUCCESS" "Security Group created with ID: $sg_id"

    aws ec2 create-tags \
        --resources "$sg_id" \
        --tags Key=Name,Value="$sg_name" \
        --region "$region" 2>>"$LOGFILE"

    echo "Security Group '$sg_name' created with ID: $sg_id"
    echo "Applying standard Linux rules..."
    log "INFO" "Applying standard Linux rules to Security Group $sg_id..."

    # Allow SSH
    aws ec2 authorize-security-group-ingress \
        --group-id "$sg_id" \
        --protocol tcp \
        --port 22 \
        --cidr 0.0.0.0/0 \
        --region "$region" 2>>"$LOGFILE"

    # Allow Ping (ICMP Echo)
    aws ec2 authorize-security-group-ingress \
        --group-id "$sg_id" \
        --protocol icmp \
        --port -1 \
        --cidr 0.0.0.0/0 \
        --region "$region" 2>>"$LOGFILE"

    # Allow all outbound traffic
    aws ec2 authorize-security-group-egress \
        --group-id "$sg_id" \
        --protocol -1 \
        --port -1 \
        --cidr 0.0.0.0/0 \
        --region "$region" 2>>"$LOGFILE"

    if [[ $? -eq 0 ]]; then
        log "SUCCESS" "Standard rules applied successfully to Security Group $sg_id."
        echo "Standard rules applied successfully."
    else
        log "ERROR" "Failed to apply standard rules to Security Group $sg_id."
        echo "Failed to apply some or all standard rules."
        return 1
    fi

    return 0
}

# Check if AWS CLI is installed
if ! command -v aws &> /dev/null; then
    log "ERROR" "AWS CLI is not installed."
    echo "AWS CLI is not installed. Please install it first."
    exit 1
fi

# Check if user is authenticated
if ! aws sts get-caller-identity &> /dev/null; then
    log "ERROR" "User is not authenticated with AWS."
    echo "You are not authenticated with AWS. Please configure your credentials."
    exit 1
fi

# Call the function to create the Security Group
create_security_group

# Pause for user input
read -rp "Press [Enter] to return to the Network menu..."

# Return to the menu (change as needed)
source "$(dirname "$0")/securitygroup_menu.bash"

# End of script
exit 0
