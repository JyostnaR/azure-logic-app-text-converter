#!/bin/bash

# Azure Service Principal Creation Script for GitHub Actions
# This script creates a service principal for GitHub Actions deployment

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}Azure Service Principal Creation Script${NC}"
echo "=============================================="

# Check if Azure CLI is installed
if ! command -v az &> /dev/null; then
    echo -e "${RED}Error: Azure CLI is not installed. Please install it first.${NC}"
    echo "Visit: https://docs.microsoft.com/en-us/cli/azure/install-azure-cli"
    exit 1
fi

# Check if user is logged in
if ! az account show &> /dev/null; then
    echo -e "${YELLOW}You are not logged in to Azure. Please log in first.${NC}"
    az login
fi

# Get current subscription
SUBSCRIPTION_ID=$(az account show --query id --output tsv)
SUBSCRIPTION_NAME=$(az account show --query name --output tsv)
echo -e "${GREEN}Current subscription:${NC} $SUBSCRIPTION_NAME ($SUBSCRIPTION_ID)"

# Get resource group name
read -p "Enter resource group name (default: rg-text-to-json-converter): " RESOURCE_GROUP_NAME
RESOURCE_GROUP_NAME=${RESOURCE_GROUP_NAME:-rg-text-to-json-converter}

# Get service principal name
read -p "Enter service principal name (default: github-actions-logic-app): " SP_NAME
SP_NAME=${SP_NAME:-github-actions-logic-app}

echo -e "\n${YELLOW}Creating service principal...${NC}"

# Create service principal
SP_OUTPUT=$(az ad sp create-for-rbac \
    --name "$SP_NAME" \
    --role contributor \
    --scopes "/subscriptions/$SUBSCRIPTION_ID" \
    --sdk-auth \
    --output json)

echo -e "${GREEN}Service principal created successfully!${NC}"

# Display the output
echo -e "\n${YELLOW}=== Service Principal Credentials ===${NC}"
echo "Copy this JSON and add it as a GitHub secret named 'AZURE_CREDENTIALS':"
echo -e "${GREEN}"
echo "$SP_OUTPUT"
echo -e "${NC}"

# Create formatted output for easy copying
echo -e "\n${YELLOW}=== GitHub Secrets to Add ===${NC}"
echo "1. Go to your GitHub repository"
echo "2. Navigate to Settings → Secrets and variables → Actions"
echo "3. Add the following secrets:"
echo ""
echo -e "${GREEN}Secret Name: AZURE_CREDENTIALS${NC}"
echo -e "${GREEN}Secret Value:${NC}"
echo "$SP_OUTPUT"
echo ""
echo -e "${GREEN}Secret Name: AZURE_SUBSCRIPTION_ID${NC}"
echo -e "${GREEN}Secret Value: $SUBSCRIPTION_ID${NC}"

# Save to file for reference
OUTPUT_FILE="service-principal-credentials.json"
echo "$SP_OUTPUT" > "$OUTPUT_FILE"
echo -e "\n${YELLOW}Credentials saved to: $OUTPUT_FILE${NC}"
echo -e "${RED}IMPORTANT: Keep this file secure and delete it after adding to GitHub secrets!${NC}"

# Verify service principal
echo -e "\n${YELLOW}Verifying service principal...${NC}"
SP_APP_ID=$(echo "$SP_OUTPUT" | jq -r '.clientId')
az ad sp show --id "$SP_APP_ID" --query "{displayName:displayName, appId:appId}" --output table

echo -e "\n${GREEN}=== Next Steps ===${NC}"
echo "1. Add the secrets to your GitHub repository"
echo "2. Push your code to trigger the GitHub Actions workflow"
echo "3. Monitor the deployment in the Actions tab"
echo "4. Delete the credentials file: rm $OUTPUT_FILE"

echo -e "\n${GREEN}Service principal setup completed!${NC}"
