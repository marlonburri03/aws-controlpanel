#!/bin/bash

# Standardregion für AWS-CLI-Befehle
AWS_REGION="us-east-1"


# Standard-Availability Zones für Subnets
#AZ1="${AWS_REGION}a"
#AZ2="${AWS_REGION}b"

# AMI & Instanzkonfiguration
#AMI_ID="ami-0e2c8caa4b6378d8c"
INSTANCE_TYPE="t2.micro"

# SSH Key für EC2-Instanzen
KEY_NAME="vockey"

# Cloud-Init Datei für User Data
#USER_DATA_FILE="$CONFDIR/user-data-template.yml"
