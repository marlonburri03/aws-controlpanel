#!/bin/bash
source "$(dirname "${BASH_SOURCE[0]}")/../lib/init_env.bash"

log "INFO" "Starting Script: $(basename "$0")"

list_running_instances() {
    #log "INFO" "Listing running EC2-Instancen"
    echo "Available running EC2-Instances:"
    aws ec2 describe-instances \
        --filters "Name=instance-state-name,Values=running" \
        --query 'Reservations[*].Instances[*].[InstanceId,Tags[?Key==`Name`].Value | [0],State.Name]' \
        --output table
}

# delete EC2 instance
delete_ec2_instance() {
    #log "INFO" "Start deleting process for EC2-Instances"
    list_running_instances
    read -rp "Set the instance ID to be deleted: " instance_id
    if [[ -z "$instance_id" ]]; then
        log "ERROR" "No Instance ID set"
        echo "Instance ID can not be empty."
        return 1
    fi
    log "INFO" "Deleting EC2-Instance with ID: $instance_id"
    echo "Deleting EC2-Instance with ID: $instance_id..."
    aws ec2 terminate-instances --instance-ids "$instance_id"
    if [[ $? -ne 0 ]]; then
        log "ERROR" "Error deleting the Instance $instance_id"
        echo "Error deleting the Instance $instance_id."
        return 1
    fi
    log "INFO" "Instance $instance_id has been deleted."
    echo "Instance $instance_id has been deleted."
    return 0
}

# run functions
check_aws_requirements
delete_ec2_instance

# end of script
read -rp "Drücke [Enter], um zum Menü zurückzukehren..."

source "$DIR/main.bash"
exit 0
