#!/bin/bash
source "$(dirname "$0")/init_env.bash"

get_latest_ami() {
    local owner=$1
    local name_filter=$2

    aws ec2 describe-images \
        --owners "$owner" \
        --filters "Name=name,Values=$name_filter" "Name=state,Values=available" \
        --query 'Images | sort_by(@, &CreationDate)[-1].ImageId' \
        --output text
}

list_key_pairs() {
    echo "Verfügbare Key Pairs:"
    aws ec2 describe-key-pairs --query 'KeyPairs[*].KeyName' --output table
}

list_security_groups() {
    echo "Verfügbare Security Groups:"
    aws ec2 describe-security-groups \
        --query 'SecurityGroups[*].[GroupId,GroupName,Description]' \
        --output table
}

list_subnets() {
    echo "Verfügbare Subnets:"
    aws ec2 describe-subnets \
        --query 'Subnets[*].[SubnetId,VpcId,AvailabilityZone,CidrBlock]' \
        --output table
}

list_instance_types() {
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

    list_subnets
    read -rp "Gib die Subnet ID ein (z.B. subnet-0abc1234567890def): " SUBNET_ID

    read -rp "Gib einen Namen für die Instanz ein: " TAG_NAME

    if [[ -z "$AMI_ID" || -z "$INSTANCE_TYPE" || -z "$KEY_NAME" || -z "$SECURITY_GROUP_ID" || -z "$SUBNET_ID" || -z "$TAG_NAME" ]]; then
        echo "Alle Eingabefelder sind erforderlich."
        return 1
    fi

    echo "Erstelle EC2-Instanz..."

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
      echo "Fehler beim Erstellen der Instanz."
      return 1
    fi

    echo "Instanz erstellt mit ID: $INSTANCE_ID"

    echo "Warte, bis die Instanz in den Zustand 'running' wechselt..."
    aws ec2 wait instance-running --instance-ids "$INSTANCE_ID"

    PUBLIC_IP=$(aws ec2 describe-instances \
      --instance-ids "$INSTANCE_ID" \
      --query 'Reservations[0].Instances[0].PublicIpAddress' \
      --output text)

    echo "Instanz ist gestartet. Öffentliche IP: $PUBLIC_IP"
    return 0
}

if ! command -v aws &> /dev/null; then
    echo "AWS CLI ist nicht installiert. Bitte zuerst installieren."
    exit 1
fi

if ! aws sts get-caller-identity &> /dev/null; then
    echo "Keine AWS-Authentifizierung gefunden. Bitte AWS-Zugangsdaten konfigurieren."
    exit 1
fi

create_ec2_instance

read -rp "Drücke [Enter], um zum Menü zurückzukehren..."

source "$DIR/main.bash"

exit 0
