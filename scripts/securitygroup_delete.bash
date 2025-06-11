#!/bin/bash
source "$(dirname "${BASH_SOURCE[0]}")/../lib/init_env.bash"

log "INFO" "Starting Script: $(basename "$0")"

# Delete an existing Security Group
delete_security_group() {
    read -rp "Enter the AWS region: " region

    if [[ -z "$region" ]]; then
        log "ERROR" "Region wurde nicht angegeben."
        echo "Region is required."
        return 1
    fi

    #log "INFO" "Rufe bestehende Security Groups in Region '$region' ab..."
    echo "Fetching existing Security Groups in region '$region'..."
    aws ec2 describe-security-groups \
        --region "$region" \
        --query "SecurityGroups[*].{ID:GroupId,Name:GroupName,Description:Description,VPC:VpcId}" \
        --output table

    read -rp "Enter the Security Group ID to delete (e.g., sg-0abc1234def567890): " sg_id

    if [[ -z "$sg_id" ]]; then
        log "ERROR" "Security Group ID wurde nicht angegeben."
        echo "Security Group ID is required."
        return 1
    fi

    log "INFO" "Versuche, Security Group '$sg_id' in Region '$region' zu löschen..."
    echo "Deleting Security Group '$sg_id'..."

    if aws ec2 delete-security-group --group-id "$sg_id" --region "$region"; then
        log "SUCCESS" "Security Group '$sg_id' erfolgreich gelöscht."
        echo "Security Group '$sg_id' deleted successfully."
    else
        log "ERROR" "Fehler beim Löschen der Security Group '$sg_id'. Eventuell in Verwendung oder falsche ID."
        echo "Failed to delete Security Group. It might be in use or the ID is incorrect."
        return 1
    fi

    return 0
}

# Check if AWS CLI is installed
if ! command -v aws &> /dev/null; then
    log "ERROR" "AWS CLI ist nicht installiert."
    echo "AWS CLI is not installed. Please install it first."
    exit 1
fi

# Check if user is authenticated
if ! aws sts get-caller-identity &> /dev/null; then
    log "ERROR" "Benutzer ist nicht bei AWS authentifiziert."
    echo "You are not authenticated with AWS. Please configure your credentials."
    exit 1
fi

# Call the function to delete the Security Group
delete_security_group

# Pause for user input
read -rp "Press [Enter] to return to the Network menu..."

# Return to the menu (adjust if needed)
source "$(dirname "$0")/securitygroup_menu.bash"

# End of script
exit 0
