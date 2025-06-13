#!/bin/bash
source "$(dirname "${BASH_SOURCE[0]}")/../lib/init_env.bash"

log "INFO" "Starting Script: $(basename "$0")"

get_latest_ami() {
    local owner=$1
    local name_filter=$2

    #log "DEBUG" "get newest AMI for $owner with filter $name_filter"
    aws ec2 describe-images \
        --owners "$owner" \
        --filters "Name=name,Values=$name_filter" "Name=state,Values=available" \
        --query 'Images | sort_by(@, &CreationDate)[-1].ImageId' \
        --output text
}

list_key_pairs() {
    #log "INFO" "Listing Key Pairs"
    echo "Available Key Pairs:"
    aws ec2 describe-key-pairs --query 'KeyPairs[*].KeyName' --output table
}

list_security_groups() {
    #log "INFO" "Listing Security Groups"
    echo "Available Security Groups:"
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
        log "ERROR" "VPC of the Security Group $security_group_id couldnt be found."
        return 1
    fi

    #log "INFO" "Liste Subnets in VPC $vpc_id"
    echo "Verfügbare Subnets in VPC $vpc_id:"
    aws ec2 describe-subnets \
        --filters "Name=vpc-id,Values=$vpc_id" \
        --query 'Subnets[*].[SubnetId,VpcId,AvailabilityZone,CidrBlock]' \
        --output table
}

#list_instance_types() {
    #log "INFO" "Listing Instance Types"
    #echo "Instance Types (example):"
    #cat <<EOF
#t2.nano
#t2.micro
#t2.small
#t3.micro
#t3.small
#m5.large
#m5.xlarge
#EOF
#}

list_latest_amis() {
    #log "INFO" "List newest AMIs"
    echo "Newest AMI-IDs of the favourite Distributions:"
    amazon_ami=$(get_latest_ami amazon "amzn2-ami-hvm-2.0.*-x86_64-gp2")
    canonical_ami=$(get_latest_ami 099720109477 "ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*")
    redhat_ami=$(get_latest_ami 309956199498 "RHEL-8.*_HVM-*-x86_64-*")

    printf "Amazon Linux 2 (amazon): %s\n" "$amazon_ami"
    printf "Ubuntu 20.04 LTS (canonical): %s\n" "$canonical_ami"
    printf "Red Hat Enterprise Linux 8 (redhat): %s\n" "$redhat_ami"
    echo
}

select_user_data_file() {
  echo "Available User Data files:"
  echo "1) Template_Linux_Webserver.yaml"
  echo "2) Template_Ubuntu.yaml"
  echo "3) Template_Ubuntu_Docker.yaml"

  while true; do
    read -p "Please enter the number of the desired User Data file (1-3): " choice
    case $choice in
      1) file="Template_Linux_Webserver.yaml"; break ;;
      2) file="Template_Ubuntu.yaml"; break ;;
      3) file="Template_Ubuntu_Docker.yaml"; break ;;
      *) echo "Invalid input. Please enter 1, 2, or 3." ;;
    esac
  done
    USER_DATA_FILE="$ETCDIR/$file"
  echo "You selected: $USER_DATA_FILE"
}

create_ec2_instance() {
    list_latest_amis
    read -rp "Set AMI ID (example: ami-0abcdef1234567890): " AMI_ID

    select_user_data_file
    if [[ ! -f "$USER_DATA_FILE" ]]; then
        log "ERROR" "User Data file $USER_DATA_FILE does not exist."
        echo "User Data file does not exist. Please check the path."
        return 1
    fi

    #list_instance_types
    #read -rp "Set Instancetype  (z.B. t2.micro): " INSTANCE_TYPE

    #list_key_pairs
    #read -rp "Set Key Pair name (z.B. VOCKEY): " KEY_NAME

    list_security_groups
    read -rp "Gib die Security Group ID ein (z.B. sg-0123456789abcdef0): " SECURITY_GROUP_ID

    list_matching_subnets "$SECURITY_GROUP_ID"
    read -rp "Gib die Subnet ID ein (z.B. subnet-0abc1234567890def): " SUBNET_ID

    # check if Security Group and Subnet belong to same VPC 
    SEC_GROUP_VPC_ID=$(aws ec2 describe-security-groups \
        --group-ids "$SECURITY_GROUP_ID" \
        --query 'SecurityGroups[0].VpcId' \
        --output text)

    SUBNET_VPC_ID=$(aws ec2 describe-subnets \
        --subnet-ids "$SUBNET_ID" \
        --query 'Subnets[0].VpcId' \
        --output text)

    if [[ "$SEC_GROUP_VPC_ID" != "$SUBNET_VPC_ID" ]]; then
        log "ERROR" "Security Group ($SEC_GROUP_VPC_ID) and Subnet ($SUBNET_VPC_ID) belongs to different VPCs."
        echo "Invalid combination, please restart."
        return 1
    fi

    read -rp "Set namen for your Instance: " TAG_NAME

    # validation
    if [[ -z "$AMI_ID" || -z "$INSTANCE_TYPE" || -z "$KEY_NAME" || -z "$SECURITY_GROUP_ID" || -z "$SUBNET_ID" || -z "$TAG_NAME" ]]; then
        log "ERROR" "Not all vars used"
        echo "All vars must be set."
        return 1
    fi

    # validation
    if [[ ! "$AMI_ID" =~ ^ami-[0-9a-fA-F]{8,17}$ ]]; then
        log "ERROR" "Invalid AMI-ID: $AMI_ID"
        echo "Please set valid AMI-ID with formatting 'ami-xxxxxxxxxxxxxxxxx'."
        return 1
    fi

    if [[ ! "$SECURITY_GROUP_ID" =~ ^sg-[0-9a-fA-F]{8,17}$ ]]; then
        log "ERROR" "Invalid Security Group ID: $SECURITY_GROUP_ID"
        echo "Please set valid Security Group ID with formatting 'sg-xxxxxxxxxxxxxxxxx'."
        return 1
    fi

    if [[ ! "$SUBNET_ID" =~ ^subnet-[0-9a-fA-F]{8,17}$ ]]; then
        log "ERROR" "Invalid Subnet ID: $SUBNET_ID"
        echo "Please set valid Subnet ID with formatting 'subnet-xxxxxxxxxxxxxxxxx'."
        return 1
    fi

    valid_instance_types=("t2.nano" "t2.micro" "t2.small" "t3.micro" "t3.small" "m5.large" "m5.xlarge")
    if [[ ! " ${valid_instance_types[*]} " =~ " ${INSTANCE_TYPE} " ]]; then
        log "ERROR" "Invalid Instanztyp: $INSTANCE_TYPE"
        echo "Please set valid Instancetype."
        return 1
    fi

    log "INFO" "Create EC2-Instance with AMI $AMI_ID, Typ $INSTANCE_TYPE, Key $KEY_NAME, SG $SECURITY_GROUP_ID, Subnet $SUBNET_ID"

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
        log "ERROR" "Error creating instance."
        echo "Error creating instance."
        return 1
    fi

    log "INFO" "Instance successful created: $INSTANCE_ID"
    echo "Instance created with ID: $INSTANCE_ID"

    echo "Wait, until instance is 'running'..."
    #log "INFO" "Wait, until instance is 'running' $INSTANCE_ID."
    aws ec2 wait instance-running --instance-ids "$INSTANCE_ID"

    PUBLIC_IP=$(aws ec2 describe-instances \
      --instance-ids "$INSTANCE_ID" \
      --query 'Reservations[0].Instances[0].PublicIpAddress' \
      --output text)

    log "INFO" "Instance $INSTANCE_ID has been started withIP $PUBLIC_IP"
    echo "Instance is started. Public IP: $PUBLIC_IP"
    return 0
}

# run functions
check_aws_requirements
create_ec2_instance

# end of script