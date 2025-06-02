#!/bin/bash
source "$(dirname "$0")/init_env.bash"

list_running_instances() {
    echo "Verfügbare laufende EC2-Instanzen:"
    aws ec2 describe-instances \
        --filters "Name=instance-state-name,Values=running" \
        --query 'Reservations[*].Instances[*].[InstanceId,Tags[?Key==`Name`].Value | [0],State.Name]' \
        --output table
}

# Delete EC2 instance
delete_ec2_instance() {
    list_running_instances
    read -rp "Gib die Instance ID ein, die gelöscht werden soll: " instance_id
    if [[ -z "$instance_id" ]]; then
        echo "Instance ID darf nicht leer sein."
        return 1
    fi
    echo "Lösche EC2-Instanz mit ID: $instance_id..."
    aws ec2 terminate-instances --instance-ids "$instance_id"
    if [[ $? -ne 0 ]]; then
        echo "Fehler beim Löschen der Instanz $instance_id."
        return 1
    fi
    echo "Instanz $instance_id wurde erfolgreich gelöscht."
    return 0
}

# Prüfen ob AWS CLI installiert ist
if ! command -v aws &> /dev/null; then
    echo "AWS CLI ist nicht installiert. Bitte zuerst installieren."
    exit 1
fi

# Prüfen ob der Nutzer authentifiziert ist
if ! aws sts get-caller-identity &> /dev/null; then
    echo "Keine AWS-Authentifizierung gefunden. Bitte Zugangsdaten konfigurieren."
    exit 1
fi

# Funktion zum Löschen aufrufen
delete_ec2_instance

# Auf Eingabe warten bevor zum Menü zurück
read -rp "Drücke [Enter], um zum EC2-Menü zurückzukehren..."

# Zurück zum Menü
source "$DIR/ec2_menu.bash"

exit 0
