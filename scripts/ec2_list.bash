#!/bin/bash
source "$(dirname "${BASH_SOURCE[0]}")/../lib/init_env.bash"

log "INFO" "Starte Script: $(basename "$0")"

# List EC2 instances
list_ec2_instances() {
    #log "INFO" "Listing EC2 instances..."
    aws ec2 describe-instances \
        --query 'Reservations[*].Instances[*].[InstanceId,State.Name,PublicIpAddress,Tags[?Key==`Name`].Value | [0]]' \
        --output table 2>>"$LOGFILE"
    if [[ $? -ne 0 ]]; then
        log "ERROR" "Failed to list EC2 instances."
        return 1
    fi
    log "SUCCESS" "Successfully listed EC2 instances."
}

# Check if AWS CLI is installed 
if ! command -v aws &> /dev/null; then
    log "ERROR" "AWS CLI is not installed. Please install it first."
    exit 1
fi

# Check if user is authenticated
if ! aws sts get-caller-identity &> /dev/null; then
    log "ERROR" "You are not authenticated with AWS. Please configure your credentials."
    exit 1
fi

# Call the function to list instances
list_ec2_instances

# Pause for user input
read -rp "Press [Enter] to return to the EC2 menu..."

# Return to EC2 menu
#log "INFO" "Returning to EC2 menu..."
source "$DIR/ec2_menu.bash"

# End of script
exit 0
