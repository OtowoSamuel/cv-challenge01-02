#!/bin/bash

REGION="eu-north-1"

# Get all VPCs
VPC_IDS=$(aws ec2 describe-vpcs --query "Vpcs[*].VpcId" --output text --region $REGION)

for VPC_ID in $VPC_IDS; do
  echo "Deleting resources in VPC: $VPC_ID"

  # Delete NAT Gateways
  NAT_GATEWAYS=$(aws ec2 describe-nat-gateways --query "NatGateways[*].NatGatewayId" --output text --region $REGION)
  for NAT in $NAT_GATEWAYS; do
    aws ec2 delete-nat-gateway --nat-gateway-id $NAT --region $REGION
  done

  # Delete Subnets
  SUBNETS=$(aws ec2 describe-subnets --filters "Name=vpc-id,Values=$VPC_ID" --query "Subnets[*].SubnetId" --output text --region $REGION)
  for SUBNET in $SUBNETS; do
    aws ec2 delete-subnet --subnet-id $SUBNET --region $REGION
  done

  # Delete Route Tables
  ROUTE_TABLES=$(aws ec2 describe-route-tables --filters "Name=vpc-id,Values=$VPC_ID" --query "RouteTables[*].RouteTableId" --output text --region $REGION)
  for RT in $ROUTE_TABLES; do
    aws ec2 delete-route-table --route-table-id $RT --region $REGION
  done

  # Delete Internet Gateways
  IGWS=$(aws ec2 describe-internet-gateways --query "InternetGateways[*].InternetGatewayId" --output text --region $REGION)
  for IGW in $IGWS; do
    aws ec2 detach-internet-gateway --internet-gateway-id $IGW --vpc-id $VPC_ID --region $REGION
    aws ec2 delete-internet-gateway --internet-gateway-id $IGW --region $REGION
  done

  # Delete Security Groups (excluding default)
  SGROUPS=$(aws ec2 describe-security-groups --query "SecurityGroups[?GroupName!='default'].GroupId" --output text --region $REGION)
  for SG in $SGROUPS; do
    aws ec2 delete-security-group --group-id $SG --region $REGION
  done

  # Finally, delete the VPC
  aws ec2 delete-vpc --vpc-id $VPC_ID --region $REGION
  echo "Deleted VPC: $VPC_ID"
done

#Delete Key Pair
  aws ec2 delete-key-pair --key-name otowok
echo "All VPCs and dependencies deleted successfully!"
