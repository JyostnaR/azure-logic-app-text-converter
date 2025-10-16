#!/bin/bash

# Azure Logic App Deployment Script
# This script deploys the Text-to-JSON converter Logic App to Azure
# Supports both local deployment and GitHub Actions environment

set -e

# Configuration - can be overridden by environment variables
RESOURCE_GROUP_NAME="${RESOURCE_GROUP_NAME:-rg-text-to-json-converter}"
LOCATION="${LOCATION:-East US}"
TEMPLATE_FILE="template.json"
PARAMETERS_FILE="parameters.json"
DEPLOYMENT_NAME="text-to-json-deployment-$(date +%Y%m%d-%H%M%S)"
ENVIRONMENT="${ENVIRONMENT:-dev}"

# GitHub Actions detection
if [ "$GITHUB_ACTIONS" = "true" ]; then
    echo "Running in GitHub Actions environment"
    USE_GITHUB_ACTIONS=true
else
    USE_GITHUB_ACTIONS=false
fi

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}Azure Logic App Deployment Script${NC}"
echo "=================================="

# Check if Azure CLI is installed
if ! command -v az &> /dev/null; then
    echo -e "${RED}Error: Azure CLI is not installed. Please install it first.${NC}"
    echo "Visit: https://docs.microsoft.com/en-us/cli/azure/install-azure-cli"
    exit 1
fi

# Check if user is logged in (skip in GitHub Actions)
if [ "$USE_GITHUB_ACTIONS" = "false" ]; then
    if ! az account show &> /dev/null; then
        echo -e "${YELLOW}You are not logged in to Azure. Please log in first.${NC}"
        az login
    fi
else
    echo -e "${GREEN}Using service principal authentication from GitHub Actions${NC}"
fi

# Get current subscription
SUBSCRIPTION_ID=$(az account show --query id --output tsv)
echo -e "${GREEN}Current subscription:${NC} $SUBSCRIPTION_ID"

# Create resource group if it doesn't exist
echo -e "\n${YELLOW}Creating resource group...${NC}"
if az group show --name $RESOURCE_GROUP_NAME &> /dev/null; then
    echo -e "${GREEN}Resource group '$RESOURCE_GROUP_NAME' already exists.${NC}"
else
    az group create --name $RESOURCE_GROUP_NAME --location "$LOCATION"
    echo -e "${GREEN}Resource group '$RESOURCE_GROUP_NAME' created successfully.${NC}"
fi

# Set Logic App name based on environment
if [ "$ENVIRONMENT" = "prod" ]; then
    LOGIC_APP_NAME="text-to-json-converter-prod"
elif [ "$ENVIRONMENT" = "staging" ]; then
    LOGIC_APP_NAME="text-to-json-converter-staging"
else
    LOGIC_APP_NAME="text-to-json-converter-dev"
fi

# Deploy the Logic App
echo -e "\n${YELLOW}Deploying Logic App...${NC}"
deployment_result=$(az deployment group create \
    --resource-group $RESOURCE_GROUP_NAME \
    --template-file $TEMPLATE_FILE \
    --parameters @$PARAMETERS_FILE \
    --parameters logicAppName=$LOGIC_APP_NAME \
    --parameters location="$LOCATION" \
    --parameters environment=$ENVIRONMENT \
    --name $DEPLOYMENT_NAME \
    --output json)

# Extract Logic App resource ID from deployment result
LOGIC_APP_RESOURCE_ID=$(echo $deployment_result | jq -r '.properties.outputs.logicAppResourceId.value')

echo -e "${GREEN}Deployment completed successfully!${NC}"

# Get the HTTP trigger URL
echo -e "\n${YELLOW}Retrieving HTTP trigger URL...${NC}"
TRIGGER_URL=$(az logic workflow show \
    --resource-group $RESOURCE_GROUP_NAME \
    --name $LOGIC_APP_NAME \
    --query "accessEndpoint" \
    --output tsv)

echo -e "\n${GREEN}=== Deployment Summary ===${NC}"
echo -e "Environment: ${GREEN}$ENVIRONMENT${NC}"
echo -e "Resource Group: ${GREEN}$RESOURCE_GROUP_NAME${NC}"
echo -e "Logic App Name: ${GREEN}$LOGIC_APP_NAME${NC}"
echo -e "Location: ${GREEN}$LOCATION${NC}"
echo -e "HTTP Trigger URL: ${GREEN}$TRIGGER_URL${NC}"
echo -e "Deployment Name: ${GREEN}$DEPLOYMENT_NAME${NC}"

# GitHub Actions specific output
if [ "$USE_GITHUB_ACTIONS" = "true" ]; then
    echo -e "\n${YELLOW}=== GitHub Actions Environment Variables ===${NC}"
    echo "::set-output name=resource_group::$RESOURCE_GROUP_NAME"
    echo "::set-output name=logic_app_name::$LOGIC_APP_NAME"
    echo "::set-output name=trigger_url::$TRIGGER_URL"
    echo "::set-output name=environment::$ENVIRONMENT"
fi

echo -e "\n${YELLOW}=== How to Test ===${NC}"
echo "You can test the Logic App by sending a POST request to:"
echo -e "${GREEN}$TRIGGER_URL${NC}"
echo ""
echo "Example request body:"
echo '{'
echo '  "fileName": "sample.txt",'
echo '  "fileContent": "SGVsbG8gV29ybGQ=",'
echo '  "contentType": "text/plain"'
echo '}'
echo ""
echo "Note: 'fileContent' should be Base64 encoded."

echo -e "\n${GREEN}Deployment completed successfully!${NC}"
