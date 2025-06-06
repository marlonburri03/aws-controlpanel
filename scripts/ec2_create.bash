#!/bin/bash
source "$(dirname "$0")/init_env.bash"

log "INFO" "Starte Skript: $(basename "$0")"

get_latest_ami() {
    local owner=$1
    local name_filter=$2

    log "DEBUG" "Suche neuestes AMI für $owner mit Filter $name_filter"
    aws ec2 describe-images \
        --owners "$owner" \
        --filters "Name=name,Values=$name_filter" "Name=state,Values=available" \
        --query 'Images | sort_by(@, &CreationDate)[-1].ImageId' \
        --output text
}

list_key_pairs() {
    log "INFO" "Liste Key Pairs"
    echo "Verfügbare Key Pairs:"
    aws ec2 describe-key-pairs --query 'KeyPairs[*].KeyName' --output table
}

list_security_groups() {
    log "INFO" "Liste Security Groups"
    echo "Verfügbare Security Groups:"
    aws ec2 describe-security-groups \
        --query 'SecurityGroups[*].[GroupId,GroupName,Description]' \
        --output table
}

list_matching_subnets() {
    local security_group_id=$1

    local vpc_id=$(aws ec2 describe-security-groups \
        --group-ids "$security_group_id" \
        --query 'SecurityGroups[0].VpcId' \
        --output text)

    if [[ -z "$vpc_id" ]]; then
        log "ERROR" "Konnte VPC der Security Group $security_group_id nicht ermitteln."
        return 1
    fi

    log "INFO" "Liste Subnets in VPC $vpc_id"
    echo "Verfügbare Subnets in VPC $vpc_id:"
    aws ec2 describe-subnets \
        --filters "Name=vpc-id,Values=$vpc_id" \
        --query 'Subnets[*].[SubnetId,VpcId,AvailabilityZone,CidrBlock]' \
        --output table
}

list_instance_types() {
    log "INFO" "Liste gängige Instanztypen"
    echo "Gängige Instanztypen (Beispiel):"
    cat <<EOF
t2.nano
t2.micro
t2.small
t3.micro
t3.small
m5.large
m5.xlarge
EOF
}

list_latest_amis() {
    log "INFO" "Liste neueste AMIs"
    echo "Neueste AMI-IDs der beliebtesten Anbieter:"
    amazon_ami=$(get_latest_ami amazon "amzn2-ami-hvm-2.0.*-x86_64-gp2")
    canonical_ami=$(get_latest_ami 099720109477 "ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*")
    redhat_ami=$(get_latest_ami 309956199498 "RHEL-8.*_HVM-*-x86_64-*")

    printf "Amazon Linux 2 (amazon): %s\n" "$amazon_ami"
    printf "Ubuntu 20.04 LTS (canonical): %s\n" "$canonical_ami"
    printf "Red Hat Enterprise Linux 8 (redhat): %s\n" "$redhat_ami"
    echo
}

create_ec2_instance() {
    list_latest_amis
    read -rp "Gib die AMI ID ein (z.B. ami-0abcdef1234567890): " AMI_ID

    list_instance_types
    read -rp "Gib den Instanztyp ein (z.B. t2.micro): " INSTANCE_TYPE

    list_key_pairs
    read -rp "Gib den Key Pair Namen ein (z.B. VOCKEY): " KEY_NAME

    list_security_groups
    read -rp "Gib die Security Group ID ein (z.B. sg-0123456789abcdef0): " SECURITY_GROUP_ID

    list_matching_subnets "$SECURITY_GROUP_ID"
    read -rp "Gib die Subnet ID ein (z.B. subnet-0abc1234567890def): " SUBNET_ID

    # Prüfe, ob Security Group und Subnet zur gleichen VPC gehören
    SEC_GROUP_VPC_ID=$(aws ec2 describe-security-groups \
        --group-ids "$SECURITY_GROUP_ID" \
        --query 'SecurityGroups[0].VpcId' \
        --output text)

    SUBNET_VPC_ID=$(aws ec2 describe-subnets \
        --subnet-ids "$SUBNET_ID" \
        --query 'Subnets[0].VpcId' \
        --output text)

    if [[ "$SEC_GROUP_VPC_ID" != "$SUBNET_VPC_ID" ]]; then
        log "ERROR" "Die Security Group ($SEC_GROUP_VPC_ID) und das Subnet ($SUBNET_VPC_ID) gehören zu unterschiedlichen VPCs."
        echo "Ungültige Kombination – bitte neu starten."
        return 1
    fi

    read -rp "Gib einen Namen für die Instanz ein: " TAG_NAME

    # Validierung der Eingaben
    if [[ -z "$AMI_ID" || -z "$INSTANCE_TYPE" || -z "$KEY_NAME" || -z "$SECURITY_GROUP_ID" || -z "$SUBNET_ID" || -z "$TAG_NAME" ]]; then
        log "ERROR" "Nicht alle Eingabefelder wurden ausgefüllt"
        echo "Alle Eingabefelder sind erforderlich."
        return 1
    fi

    # Validierung der Formate der IDs und Instanztyp
    if [[ ! "$AMI_ID" =~ ^ami-[0-9a-fA-F]{8,17}$ ]]; then
        log "ERROR" "Ungültige AMI-ID: $AMI_ID"
        echo "Bitte eine gültige AMI-ID im Format 'ami-xxxxxxxxxxxxxxxxx' eingeben."
        return 1
    fi

    if [[ ! "$SECURITY_GROUP_ID" =~ ^sg-[0-9a-fA-F]{8,17}$ ]]; then
        log "ERROR" "Ungültige Security Group ID: $SECURITY_GROUP_ID"
        echo "Bitte eine gültige Security Group ID im Format 'sg-xxxxxxxxxxxxxxxxx' eingeben."
        return 1
    fi

    if [[ ! "$SUBNET_ID" =~ ^subnet-[0-9a-fA-F]{8,17}$ ]]; then
        log "ERROR" "Ungültige Subnet ID: $SUBNET_ID"
        echo "Bitte eine gültige Subnet ID im Format 'subnet-xxxxxxxxxxxxxxxxx' eingeben."
        return 1
    fi

    valid_instance_types=("t2.nano" "t2.micro" "t2.small" "t3.micro" "t3.small" "m5.large" "m5.xlarge")
    if [[ ! " ${valid_instance_types[*]} " =~ " ${INSTANCE_TYPE} " ]]; then
        log "ERROR" "Ungültiger Instanztyp: $INSTANCE_TYPE"
        echo "Bitte einen gültigen Instanztyp aus der Liste eingeben."
        return 1
    fi

    log "INFO" "Erstelle EC2-Instanz mit AMI $AMI_ID, Typ $INSTANCE_TYPE, Key $KEY_NAME, SG $SECURITY_GROUP_ID, Subnet $SUBNET_ID"

    INSTANCE_ID=$(aws ec2 run-instances \
      --image-id "$AMI_ID" \
      --instance-type "$INSTANCE_TYPE" \
      --key-name "$KEY_NAME" \
      --security-group-ids "$SECURITY_GROUP_ID" \
      --subnet-id "$SUBNET_ID" \
      --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$TAG_NAME}]" \
      --query 'Instances[0].InstanceId' \
      --output text)

    if [[ $? -ne 0 || -z "$INSTANCE_ID" ]]; then
        log "ERROR" "Fehler beim Erstellen der Instanz."
        echo "Fehler beim Erstellen der Instanz."
        return 1
    fi

    log "INFO" "Instanz erfolgreich erstellt: $INSTANCE_ID"
    echo "Instanz erstellt mit ID: $INSTANCE_ID"

    echo "Warte, bis die Instanz in den Zustand 'running' wechselt..."
    log "INFO" "Warte auf 'running' Status für Instanz $INSTANCE_ID"
    aws ec2 wait instance-running --instance-ids "$INSTANCE_ID"

    PUBLIC_IP=$(aws ec2 describe-instances \
      --instance-ids "$INSTANCE_ID" \
      --query 'Reservations[0].Instances[0].PublicIpAddress' \
      --output text)

    log "INFO" "Instanz $INSTANCE_ID ist gestartet mit IP $PUBLIC_IP"
    echo "Instanz ist gestartet. Öffentliche IP: $PUBLIC_IP"
    return 0
}

# Voraussetzungen prüfen
if ! command -v aws &> /dev/null; then
    log "ERROR" "AWS CLI ist nicht installiert."
    echo "AWS CLI ist nicht installiert. Bitte zuerst installieren."
    exit 1
fi

if ! aws sts get-caller-identity &> /dev/null; then
    log "ERROR" "AWS-Zugangsdaten fehlen oder sind ungültig."
    echo "Keine AWS-Authentifizierung gefunden. Bitte AWS-Zugangsdaten konfigurieren."
    exit 1
fi

create_ec2_instance

read -rp "Drücke [Enter], um zum Menü zurückzukehren..."
log "INFO" "Skript abgeschlossen, kehre zurück zum Menü."

source "$DIR/main.bash"
exit 0
