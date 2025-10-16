# Azure Logic App - Text to JSON Converter

This Azure Logic App workflow receives HTTP requests containing text file content, converts the content to structured JSON format, and returns an HTTP response. The project includes automated deployment via GitHub Actions for multiple environments.

## 🚀 Quick Start

### Deploy with GitHub Actions
1. **Fork/Clone this repository**
2. **Set up Azure Service Principal** (see [GitHub Setup Guide](GITHUB_SETUP.md))
3. **Configure GitHub Secrets**
4. **Push to main branch** - automatic deployment to dev environment

### Deploy Locally
```bash
./deploy.sh
```

## Overview

The workflow performs the following operations:
1. **Receives HTTP Request**: Accepts a POST request with text file content
2. **Decodes Content**: Decodes Base64-encoded file content
3. **Processes Text**: Analyzes the text content and extracts metadata
4. **Generates JSON**: Creates a structured JSON response with file information
5. **Returns Response**: Sends back the JSON data via HTTP response

## Architecture

```
HTTP Request → Logic App → Text Processing → JSON Response
```

## Input Format

The Logic App expects a POST request with the following JSON structure:

```json
{
  "fileName": "sample.txt",
  "fileContent": "SGVsbG8gV29ybGQ=",
  "contentType": "text/plain"
}
```

### Parameters:
- **fileName** (required): Name of the file being processed
- **fileContent** (required): Base64-encoded content of the file
- **contentType** (optional): MIME type of the file content (defaults to "text/plain")

## Output Format

The Logic App returns a JSON response with the following structure:

```json
{
  "status": "success",
  "message": "File content successfully converted to JSON",
  "data": {
    "fileName": "sample.txt",
    "contentType": "text/plain",
    "fileSize": 12,
    "content": "Hello World",
    "lines": ["Hello World"],
    "wordCount": 2,
    "processedAt": "2024-01-15T10:30:00.000Z",
    "metadata": {
      "originalFileName": "sample.txt",
      "processingTimestamp": "2024-01-15T10:30:00.000Z",
      "logicAppName": "text-to-json-converter",
      "runId": "08585087761130976370"
    }
  },
  "processingInfo": {
    "processedAt": "2024-01-15T10:30:00.000Z",
    "processingTime": 150,
    "logicAppRunId": "08585087761130976370"
  }
}
```

## Files Structure

```
├── .github/
│   └── workflows/
│       └── deploy-azure-logic-app.yml  # GitHub Actions workflow
├── workflow.json          # Logic App workflow definition
├── template.json          # ARM template for deployment
├── parameters.json        # Deployment parameters
├── deploy.sh             # Deployment script (local & GitHub Actions)
├── GITHUB_SETUP.md       # GitHub setup guide
├── .gitignore            # Git ignore rules
└── README.md             # This documentation
```

## Prerequisites

### For Local Deployment
1. **Azure CLI**: Install the Azure CLI from [Microsoft Docs](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli)
2. **Azure Subscription**: You need an active Azure subscription
3. **jq** (optional): For JSON processing in the deployment script

### For GitHub Actions Deployment
1. **GitHub Account**: Repository with Actions enabled
2. **Azure Subscription**: Active subscription with contributor permissions
3. **Azure Service Principal**: For authentication (see [GitHub Setup Guide](GITHUB_SETUP.md))

## Deployment

### Option 1: GitHub Actions (Recommended for CI/CD)

1. **Set up GitHub repository**:
   - Fork or clone this repository
   - Follow the [GitHub Setup Guide](GITHUB_SETUP.md)

2. **Automatic deployment**:
   - Push to `main` branch → deploys to `dev` environment
   - Create pull request → validates deployment
   - Manual trigger → choose environment (`dev`/`staging`/`prod`)

### Option 2: Local Deployment Script

1. **Login to Azure**:
   ```bash
   az login
   ```

2. **Run the deployment script**:
   ```bash
   ./deploy.sh
   ```

   Or with custom environment:
   ```bash
   ENVIRONMENT=staging ./deploy.sh
   ```

The script will:
- Create a resource group (if it doesn't exist)
- Deploy the Logic App using ARM template
- Display the HTTP trigger URL for testing

### Option 3: Manual Deployment

1. **Create a resource group**:
   ```bash
   az group create --name rg-text-to-json-converter --location "East US"
   ```

2. **Deploy the Logic App**:
   ```bash
   az deployment group create \
     --resource-group rg-text-to-json-converter \
     --template-file template.json \
     --parameters @parameters.json
   ```

3. **Get the HTTP trigger URL**:
   ```bash
   az logic workflow show \
     --resource-group rg-text-to-json-converter \
     --name text-to-json-converter \
     --query "accessEndpoint" \
     --output tsv
   ```

## Testing

### Using curl

```bash
# Replace <TRIGGER_URL> with your actual trigger URL
curl -X POST <TRIGGER_URL> \
  -H "Content-Type: application/json" \
  -d '{
    "fileName": "sample.txt",
    "fileContent": "SGVsbG8gV29ybGQ=",
    "contentType": "text/plain"
  }'
```

### Using PowerShell

```powershell
$body = @{
    fileName = "sample.txt"
    fileContent = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes("Hello World"))
    contentType = "text/plain"
} | ConvertTo-Json

Invoke-RestMethod -Uri "<TRIGGER_URL>" -Method POST -Body $body -ContentType "application/json"
```

### Using Python

```python
import requests
import base64

# Prepare the request
url = "<TRIGGER_URL>"
text_content = "Hello World"
encoded_content = base64.b64encode(text_content.encode()).decode()

payload = {
    "fileName": "sample.txt",
    "fileContent": encoded_content,
    "contentType": "text/plain"
}

# Send the request
response = requests.post(url, json=payload)
print(response.json())
```

## Workflow Steps

The Logic App workflow consists of the following steps:

1. **Initialize Variables**: Sets up variables for storing processed data
2. **Decode Base64 Content**: Converts Base64-encoded content to readable text
3. **Set Decoded Content**: Stores the decoded content in a variable
4. **Parse Text to JSON**: Creates structured JSON with file metadata
5. **Set JSON Result**: Converts the result to string format
6. **Create Response Object**: Formats the final response
7. **Return HTTP Response**: Sends the response back to the caller

## Error Handling

The workflow includes basic error handling:
- Invalid Base64 content will cause the workflow to fail
- Missing required parameters will result in validation errors
- Processing errors are captured in the response

## Monitoring

You can monitor the Logic App runs in the Azure Portal:
1. Navigate to your Logic App in the Azure Portal
2. Go to "Overview" to see run history
3. Click on individual runs to see detailed execution steps

## Customization

### Modifying the JSON Output Structure

Edit the "Parse_Text_to_JSON" action in the workflow to customize the output structure:

```json
{
  "type": "Compose",
  "inputs": {
    "customField": "customValue",
    "yourData": "@variables('decodedContent')"
  }
}
```

### Adding Additional Processing

You can add more actions between the existing steps to:
- Validate file content
- Apply text transformations
- Extract specific patterns
- Store results in external systems

## Cost Considerations

- Logic App consumption is billed per action execution
- HTTP triggers are free
- Processing time affects billing (measured in action executions)
- Consider using Standard plan for high-volume scenarios

## Security

- The HTTP trigger is public by default
- Consider implementing authentication if needed
- Use HTTPS for all communications
- Validate input data to prevent injection attacks

## Troubleshooting

### Common Issues

1. **Deployment Fails**: Check Azure CLI login and subscription permissions
2. **Logic App Not Triggering**: Verify the trigger URL is correct
3. **Invalid Base64**: Ensure file content is properly Base64 encoded
4. **Timeout Issues**: Large files may cause timeouts; consider chunking

### Debugging

1. Check Logic App run history in Azure Portal
2. Review action inputs and outputs
3. Use the Logic App Designer for visual debugging
4. Check Azure Monitor logs for detailed error information

## GitHub Actions Features

### Workflow Triggers
- **Push to main/master**: Automatic deployment to `dev` environment
- **Pull Request**: Validates deployment without deploying
- **Manual Trigger**: Choose environment (`dev`/`staging`/`prod`) and Azure region

### Multi-Environment Support
- **dev**: Development environment (auto-deployed)
- **staging**: Staging environment (manual/PR deployment)
- **prod**: Production environment (protected with approvals)

### Automated Features
- ✅ **Resource Group Management**: Creates environment-specific resource groups
- ✅ **Logic App Deployment**: Uses ARM templates for consistent deployments
- ✅ **Endpoint Testing**: Automatically tests deployed endpoints
- ✅ **Deployment Summary**: Creates detailed deployment reports
- ✅ **Artifact Storage**: Saves deployment artifacts for 30 days

## Support

For issues or questions:
1. Check the [GitHub Setup Guide](GITHUB_SETUP.md) for deployment issues
2. Review GitHub Actions logs in the repository
3. Check the Azure Logic Apps documentation
4. Review Azure support channels
5. Check the workflow run history for specific error details
