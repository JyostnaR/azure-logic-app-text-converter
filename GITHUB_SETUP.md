# GitHub Setup Guide for Azure Logic App Deployment

This guide will help you set up GitHub Actions for automated deployment of your Azure Logic App.

## Prerequisites

1. **GitHub Account**: You need a GitHub account with repository creation permissions
2. **Azure Subscription**: Active Azure subscription with contributor permissions
3. **Azure CLI**: Installed locally for initial setup

## Step 1: Create GitHub Repository

### Option A: Create New Repository on GitHub
1. Go to [GitHub.com](https://github.com) and sign in
2. Click the "+" icon in the top right corner
3. Select "New repository"
4. Fill in the repository details:
   - **Repository name**: `azure-logic-app-text-converter`
   - **Description**: `Azure Logic App for converting text files to JSON format`
   - **Visibility**: Choose Public or Private
   - **Initialize**: Don't initialize with README (we already have files)

### Option B: Initialize Local Git Repository
```bash
# In your project directory
git init
git add .
git commit -m "Initial commit: Azure Logic App for text to JSON conversion"
git branch -M main
git remote add origin https://github.com/YOUR_USERNAME/azure-logic-app-text-converter.git
git push -u origin main
```

## Step 2: Set Up Azure Service Principal

### Create Service Principal
```bash
# Login to Azure
az login

# Set your subscription (replace with your subscription ID)
az account set --subscription "YOUR_SUBSCRIPTION_ID"

# Create service principal
az ad sp create-for-rbac --name "github-actions-logic-app" \
  --role contributor \
  --scopes /subscriptions/YOUR_SUBSCRIPTION_ID \
  --sdk-auth
```

### Copy the Output
The command will output JSON like this:
```json
{
  "clientId": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
  "clientSecret": "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx",
  "subscriptionId": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
  "tenantId": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
  "activeDirectoryEndpointUrl": "https://login.microsoftonline.com",
  "resourceManagerEndpointUrl": "https://management.azure.com/",
  "activeDirectoryGraphResourceId": "https://graph.windows.net/",
  "sqlManagementEndpointUrl": "https://management.core.windows.net:8443/",
  "galleryEndpointUrl": "https://gallery.azure.com/",
  "managementEndpointUrl": "https://management.core.windows.net/"
}
```

## Step 3: Configure GitHub Secrets

### Add Repository Secrets
1. Go to your GitHub repository
2. Click on **Settings** tab
3. In the left sidebar, click **Secrets and variables** → **Actions**
4. Click **New repository secret** and add:

#### Required Secrets:
- **Name**: `AZURE_CREDENTIALS`
  - **Value**: The entire JSON output from the service principal creation command

- **Name**: `AZURE_SUBSCRIPTION_ID`
  - **Value**: Your Azure subscription ID

### Example Secret Configuration:
```
AZURE_CREDENTIALS = {
  "clientId": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
  "clientSecret": "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx",
  "subscriptionId": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
  "tenantId": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
  "activeDirectoryEndpointUrl": "https://login.microsoftonline.com",
  "resourceManagerEndpointUrl": "https://management.azure.com/",
  "activeDirectoryGraphResourceId": "https://graph.windows.net/",
  "sqlManagementEndpointUrl": "https://management.core.windows.net:8443/",
  "galleryEndpointUrl": "https://gallery.azure.com/",
  "managementEndpointUrl": "https://management.core.windows.net/"
}

AZURE_SUBSCRIPTION_ID = xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
```

## Step 4: Set Up Environment Protection Rules (Optional)

For production deployments, set up environment protection:

1. Go to **Settings** → **Environments**
2. Click **New environment**
3. Create environments:
   - `dev`
   - `staging` 
   - `prod`

4. For each environment (especially `prod`):
   - Enable **Required reviewers**
   - Add yourself or team members as reviewers
   - Enable **Wait timer** if needed

## Step 5: Push Your Code

```bash
# Add all files
git add .

# Commit changes
git commit -m "Add GitHub Actions workflow for Azure deployment"

# Push to GitHub
git push origin main
```

## Step 6: Test the Deployment

### Automatic Deployment
- Push to `main` branch triggers deployment to `dev` environment
- Create pull requests to test staging deployments

### Manual Deployment
1. Go to **Actions** tab in your repository
2. Select **Deploy Azure Logic App** workflow
3. Click **Run workflow**
4. Choose:
   - Branch: `main`
   - Environment: `dev`, `staging`, or `prod`
   - Location: `East US` (or your preferred region)
5. Click **Run workflow**

## Step 7: Monitor Deployments

### View Deployment Status
1. Go to **Actions** tab
2. Click on your workflow run
3. View deployment summary and logs

### Check Azure Portal
1. Login to [Azure Portal](https://portal.azure.com)
2. Navigate to your resource groups:
   - `rg-text-to-json-converter-dev`
   - `rg-text-to-json-converter-staging`
   - `rg-text-to-json-converter-prod`
3. Verify Logic Apps are created and running

## Workflow Features

### Triggers
- **Push to main/master**: Deploys to `dev` environment
- **Pull Request**: Validates deployment
- **Manual**: Allows custom environment and location selection

### Multi-Environment Support
- **dev**: Development environment
- **staging**: Staging environment for testing
- **prod**: Production environment with protection rules

### Automated Testing
- Deploys Logic App
- Retrieves trigger URL
- Tests endpoint with sample data
- Creates deployment summary

## Troubleshooting

### Common Issues

1. **Authentication Failed**
   - Verify `AZURE_CREDENTIALS` secret is correctly formatted
   - Check service principal permissions

2. **Resource Group Not Found**
   - Ensure resource group creation step runs successfully
   - Check Azure region availability

3. **Logic App Deployment Failed**
   - Review ARM template syntax
   - Check parameter values

4. **Trigger URL Not Retrieved**
   - Verify Logic App was created successfully
   - Check Azure CLI permissions

### Debug Steps

1. Check GitHub Actions logs
2. Verify Azure service principal permissions
3. Test ARM template locally with Azure CLI
4. Check Azure resource group and Logic App status

## Security Best Practices

1. **Service Principal Permissions**
   - Use minimal required permissions
   - Regularly rotate credentials

2. **Environment Protection**
   - Require reviewers for production
   - Use environment-specific secrets

3. **Repository Security**
   - Keep repository private if handling sensitive data
   - Use branch protection rules

## Next Steps

After successful setup:
1. Test the deployed Logic App endpoint
2. Set up monitoring and alerting
3. Configure custom domains if needed
4. Set up backup and disaster recovery

## Support

For issues:
1. Check GitHub Actions logs
2. Review Azure deployment logs
3. Verify service principal permissions
4. Test locally with Azure CLI first
