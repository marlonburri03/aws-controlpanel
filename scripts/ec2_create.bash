#!/bin/bash

# Konfiguration
AMI_ID="ami-0abcdef1234567890"            # Beispiel: Amazon Linux 2 AMI
INSTANCE_TYPE="t2.micro"
KEY_NAME="VOCKEY"                   
SECURITY_GROUP_ID="sg-0123456789abcdef0"  # Bestehende SG
SUBNET_ID="subnet-0abc1234567890def"      # Optional: Für bestimmte VPC/Subnet
TAG_NAME="MeineInstanz"

# EC2-Instanz erstellen
echo "Erstelle EC2-Instanz..."
INSTANCE_INFO=$(aws ec2 run-instances \
  --image-id $AMI_ID \
  --instance-type $INSTANCE_TYPE \
  --key-name $KEY_NAME \
  --security-group-ids $SECURITY_GROUP_ID \
  --subnet-id $SUBNET_ID \
  --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$TAG_NAME}]" \
  --query 'Instances[0].InstanceId' \
  --output text)

if [ $? -ne 0 ]; then
  echo "Fehler beim Erstellen der Instanz."
  exit 1
fi

echo "Instanz erstellt mit ID: $INSTANCE_INFO"

# Warten, bis die Instanz läuft
echo "Warte, bis die Instanz in den Zustand 'running' wechselt..."
aws ec2 wait instance-running --instance-ids $INSTANCE_INFO

# Öffentliche IP-Adresse abrufen
PUBLIC_IP=$(aws ec2 describe-instances \
  --instance-ids $INSTANCE_INFO \
  --query 'Reservations[0].Instances[0].PublicIpAddress' \
  --output text)

echo "Instanz ist gestartet. Öffentliche IP: $PUBLIC_IP"
