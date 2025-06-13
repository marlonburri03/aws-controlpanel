#!/bin/bash
source "$(dirname "${BASH_SOURCE[0]}")/../lib/init_env.bash"

log "INFO" "Starting Script: $(basename "$0")"

# List all VPCs
list_vpcs() {
    if [[ -z "$AWS_REGION" ]]; then
        echo "Region cannot be empty."
        return 1
    fi

    echo "Listing VPCs in region '$AWS_REGION'..."
    aws ec2 describe-vpcs \
        --region "$AWS_REGION" \
        --query "Vpcs[*].{ID:VpcId,Name:Tags[?Key=='Name']|[0].Value,CIDR:CidrBlock,State:State}" \
        --output table
    return 0
}

# check resources in the VPC
check_vpc_resources() {
    local vpc_id="$1"
    local resource_found=0

    echo "Check, if ressources are available in VPC '$vpc_id'..."

    declare -A resources=(
        ["Subnets"]="aws ec2 describe-subnets --filters Name=vpc-id,Values=$vpc_id --query 'Subnets[*].SubnetId' --output text"
        ["Internet Gateways"]="aws ec2 describe-internet-gateways --filters Name=attachment.vpc-id,Values=$vpc_id --query 'InternetGateways[*].InternetGatewayId' --output text"
        ["Route Tables"]="aws ec2 describe-route-tables --filters Name=vpc-id,Values=$vpc_id --query 'RouteTables[*].RouteTableId' --output text"
        ["Security Groups"]="aws ec2 describe-security-groups --filters Name=vpc-id,Values=$vpc_id --query 'SecurityGroups[?GroupName!=\`default\`].GroupId' --output text"
        ["Network Interfaces"]="aws ec2 describe-network-interfaces --filters Name=vpc-id,Values=$vpc_id --query 'NetworkInterfaces[*].NetworkInterfaceId' --output text"
    )

    for resource in "${!resources[@]}"; do
        result=$(eval "${resources[$resource]}")
        if [[ -n "$result" ]]; then
            echo "$resource gefunden: $result"
            resource_found=1
        fi
    done

    return $resource_found
}

# Delete all ressources and VPC
force_delete_vpc() {
    local vpc_id="$1"

    echo "Detaching and deleting Internet Gateways..."
    for igw in $(aws ec2 describe-internet-gateways \
        --filters "Name=attachment.vpc-id,Values=$vpc_id" \
        --query "InternetGateways[*].InternetGatewayId" --output text); do
        aws ec2 detach-internet-gateway --internet-gateway-id "$igw" --vpc-id "$vpc_id"
        aws ec2 delete-internet-gateway --internet-gateway-id "$igw"
    done

    echo "Deleting subnets..."
    for subnet in $(aws ec2 describe-subnets \
        --filters "Name=vpc-id,Values=$vpc_id" \
        --query "Subnets[*].SubnetId" --output text); do
        aws ec2 delete-subnet --subnet-id "$subnet"
    done

    echo "Disassociating Route Tables..."
    for assoc_id in $(aws ec2 describe-route-tables \
        --filters "Name=vpc-id,Values=$vpc_id" \
        --query "RouteTables[].Associations[?Main!=\`true\`].RouteTableAssociationId" \
        --output text); do
        aws ec2 disassociate-route-table --association-id "$assoc_id"
    done

    echo "Deleting non-main Route Tables..."
    for rt in $(aws ec2 describe-route-tables \
        --filters "Name=vpc-id,Values=$vpc_id" \
        --query "RouteTables[?Associations[?Main!=\`true\`]].RouteTableId" --output text); do
        aws ec2 delete-route-table --route-table-id "$rt"
    done

    echo "Deleting non-default security groups..."
    for sg in $(aws ec2 describe-security-groups \
        --filters Name=vpc-id,Values=$vpc_id \
        --query "SecurityGroups[?GroupName!='default'].GroupId" --output text); do
        aws ec2 delete-security-group --group-id "$sg"
    done

    echo "Deleting network interfaces..."
    for eni in $(aws ec2 describe-network-interfaces \
        --filters Name=vpc-id,Values=$vpc_id \
        --query "NetworkInterfaces[*].NetworkInterfaceId" --output text); do
        aws ec2 delete-network-interface --network-interface-id "$eni"
    done

    echo "Deleting NAT Gateways..."
    for nat in $(aws ec2 describe-nat-gateways \
        --filter Name=vpc-id,Values=$vpc_id \
        --query "NatGateways[*].NatGatewayId" --output text); do
        aws ec2 delete-nat-gateway --nat-gateway-id "$nat"
        sleep 5  # wait for NAT Gateway deletion
    done

    echo "Deleting VPC Endpoints..."
    for endpoint in $(aws ec2 describe-vpc-endpoints \
        --filters Name=vpc-id,Values=$vpc_id \
        --query "VpcEndpoints[*].VpcEndpointId" --output text); do
        aws ec2 delete-vpc-endpoints --vpc-endpoint-ids "$endpoint"
    done

    echo "Deleting VPC Peering Connections..."
    for peer in $(aws ec2 describe-vpc-peering-connections \
        --query "VpcPeeringConnections[?RequesterVpcInfo.VpcId=='$vpc_id' || AccepterVpcInfo.VpcId=='$vpc_id'].VpcPeeringConnectionId" \
        --output text); do
        aws ec2 delete-vpc-peering-connection --vpc-peering-connection-id "$peer"
    done

    echo "Deleting Classic Load Balancers..."
    for elb in $(aws elb describe-load-balancers \
        --query "LoadBalancerDescriptions[?VPCId=='$vpc_id'].LoadBalancerName" --output text); do
        aws elb delete-load-balancer --load-balancer-name "$elb"
    done

    echo "Deleting Application/Network Load Balancers..."
    for elbv2 in $(aws elbv2 describe-load-balancers \
        --query "LoadBalancers[?VpcId=='$vpc_id'].LoadBalancerArn" --output text); do
        aws elbv2 delete-load-balancer --load-balancer-arn "$elbv2"
    done

    echo "Releasing Elastic IPs associated with the VPC..."
    for alloc in $(aws ec2 describe-addresses \
        --query "Addresses[?AssociationId!=null && NetworkInterfaceId!=null].AllocationId" --output text); do
        aws ec2 release-address --allocation-id "$alloc"
    done

    echo "Lösche VPC: $vpc_id"
    aws ec2 delete-vpc --vpc-id "$vpc_id"
}

# main function
delete_vpc() {
    read -rp "Enter the VPC ID to delete (e.g., vpc-123abc456def): " vpc_id

    if [[ -z "$vpc_id" || -z "$AWS_REGION" ]]; then
        echo "VPC ID and region are required."
        return 1
    fi

    echo "WARNING: Deleting a VPC will also remove all associated resources."
    check_vpc_resources "$vpc_id"
    if [[ $? -eq 1 ]]; then
        echo "There are still resources in the VPC."
        read -rp "Do you still want to delete the resources and the VPC? (y/N): " confirm
        if [[ "$confirm" =~ ^[Yy]$ ]]; then
            force_delete_vpc "$vpc_id"
        else
            echo "Deletion canceled."
            return 0
        fi
    else
        read -rp "VPC ist leer. Sicher löschen? (y/N): " confirm
        if [[ "$confirm" =~ ^[Yy]$ ]]; then
            aws ec2 delete-vpc --vpc-id "$vpc_id"
            echo "VPC $vpc_id has been deleted."
        else
            echo "Deletion canceled."
        fi
    fi
}

# run functions
check_aws_requirements
list_vpcs
delete_vpc

# end of script