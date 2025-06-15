#!/bin/bash
source "$(dirname "${BASH_SOURCE[0]}")/../lib/init_env.bash"

log "INFO" "Starting Script: $(basename "$0")"

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

# run functions
check_aws_requirements
list_ec2_instances

# end of script