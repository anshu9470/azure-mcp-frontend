#!/bin/bash

# Azure MCP Agent Frontend - Deployment Script
# Deploys to Azure Static Web Apps

set -e

# Configuration - UPDATE THESE VALUES
RESOURCE_GROUP="rg-mcp-agent"
LOCATION="australiaeast"
SWA_NAME="swa-mcp-agent-frontend"
BACKEND_URL="https://app-mcp-agent-backend.azurewebsites.net"  # Update after backend deployment

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}=== Azure MCP Agent Frontend Deployment ===${NC}"

# Check if logged in to Azure
echo -e "${YELLOW}Checking Azure CLI login status...${NC}"
if ! az account show &> /dev/null; then
    echo -e "${RED}Not logged in to Azure CLI. Please run 'az login' first.${NC}"
    exit 1
fi

# Install SWA CLI if not present
if ! command -v swa &> /dev/null; then
    echo -e "${YELLOW}Installing Azure Static Web Apps CLI...${NC}"
    npm install -g @azure/static-web-apps-cli
fi

# Build the frontend
echo -e "${YELLOW}Building frontend...${NC}"
VITE_API_URL=$BACKEND_URL npm run build

# Create Static Web App
echo -e "${YELLOW}Creating Azure Static Web App...${NC}"
az staticwebapp create \
    --name $SWA_NAME \
    --resource-group $RESOURCE_GROUP \
    --location $LOCATION \
    --sku Free \
    --output none 2>/dev/null || echo "Static Web App may already exist"

# Get deployment token
DEPLOYMENT_TOKEN=$(az staticwebapp secrets list \
    --name $SWA_NAME \
    --resource-group $RESOURCE_GROUP \
    --query "properties.apiKey" -o tsv)

# Deploy using SWA CLI
echo -e "${YELLOW}Deploying to Azure Static Web Apps...${NC}"
swa deploy ./dist \
    --deployment-token $DEPLOYMENT_TOKEN \
    --env production

# Get the URL
SWA_URL=$(az staticwebapp show \
    --name $SWA_NAME \
    --resource-group $RESOURCE_GROUP \
    --query "defaultHostname" -o tsv)

echo -e "${GREEN}=== Deployment Complete ===${NC}"
echo -e "Frontend URL: https://$SWA_URL"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "1. Update backend CORS to allow: https://$SWA_URL"
echo "2. Run: az webapp config appsettings set --resource-group $RESOURCE_GROUP --name app-mcp-agent-backend --settings FRONTEND_URL=\"https://$SWA_URL\""
