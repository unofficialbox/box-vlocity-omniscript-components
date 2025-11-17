# Box Omniscript Components

A Salesforce DX project containing Lightning Web Components and Visualforce pages for Box content upload integration with Salesforce Omniscript.

## Project Structure

- **Lightning Web Components**: `force-app/main/default/lwc/boxUploader/`
- **Visualforce Pages**: `force-app/main/default/pages/BoxContentUploader.page`
- **Source API Version**: 59.0
- **Package Directory**: `force-app` (default)

## Prerequisites

Before deploying this project, ensure you have:

1. **Salesforce CLI** installed (version 7.0 or later)
   - Download from: https://developer.salesforce.com/tools/salesforcecli
   - Verify installation: `sf --version`

2. **Access to a Salesforce Org** (Sandbox, Developer Edition, or Production)
   - Ensure you have appropriate permissions (System Administrator recommended)

3. **Required Salesforce Features**:
   - Lightning Experience enabled
   - Omniscript (OmniStudio) installed and configured
   - Visualforce pages enabled

## Authentication

You need to authenticate with your Salesforce org before deploying. Choose one of the following methods:

### Method 1: Authorize an Org (Recommended for Development)

```bash
# For production or sandbox
sf org login web --alias <your-alias> --instance-url https://login.salesforce.com

# For sandbox
sf org login web --alias <your-alias> --instance-url https://test.salesforce.com

# For scratch org (development)
sf org create scratch --definition-file config/project-scratch-def.json --alias <your-alias> --duration-days 30
```

### Method 2: Use an Existing Authenticated Org

```bash
# List all authenticated orgs
sf org list

# Set a default org
sf config set target-org <alias-or-username>
```

## Deployment Instructions

### Step 1: Set Your Target Org

```bash
# Set the default org for this project
sf config set target-org <your-org-alias>

# Or specify the org for each command using --target-org flag
```

### Step 2: Validate Deployment (Optional but Recommended)

Before deploying to production, validate your deployment:

```bash
# Validate deployment without actually deploying
sf project deploy start --source-dir force-app --dry-run --target-org <your-org-alias>
```

### Step 3: Deploy to Salesforce Org

#### Option A: Deploy All Source (Recommended)

```bash
# Deploy all source from the force-app directory
sf project deploy start --source-dir force-app --target-org <your-org-alias>
```

#### Option B: Deploy Specific Components

```bash
# Deploy only Lightning Web Components
sf project deploy start --source-dir force-app/main/default/lwc --target-org <your-org-alias>

# Deploy only Visualforce pages
sf project deploy start --source-dir force-app/main/default/pages --target-org <your-org-alias>
```

#### Option C: Deploy with Test Execution (Production)

For production deployments, run tests:

```bash
# Deploy with running all tests
sf project deploy start --source-dir force-app --target-org <your-org-alias> --test-level RunLocalTests

# Deploy with running specific test classes
sf project deploy start --source-dir force-app --target-org <your-org-alias> --tests <TestClass1>,<TestClass2>
```

### Step 4: Monitor Deployment Status

```bash
# Check deployment status
sf project deploy report --job-id <job-id>

# Or get the latest deployment status
sf project deploy report
```

### Step 5: Verify Deployment

After successful deployment, verify the components are available:

1. **Lightning Web Component**:
   - Navigate to Setup → Custom Code → Lightning Components
   - Look for "Box Content Uploader" component

2. **Visualforce Page**:
   - Navigate to Setup → Custom Code → Visualforce Pages
   - Look for "BoxContentUploader" page

3. **Test in Omniscript**:
   - Create or edit an Omniscript
   - Add the Box Content Uploader component to a step
   - Configure the required properties (accessToken, folderId)

## Quick Deployment Commands

### Deploy to Sandbox
```bash
sf org login web --alias sandbox --instance-url https://test.salesforce.com
sf config set target-org sandbox
sf project deploy start --source-dir force-app --target-org sandbox
```

### Deploy to Production
```bash
sf org login web --alias production --instance-url https://login.salesforce.com
sf config set target-org production
sf project deploy start --source-dir force-app --target-org production --test-level RunLocalTests
```

## Troubleshooting

### Common Issues

1. **Authentication Errors**
   ```bash
   # Re-authenticate if session expired
   sf org login web --alias <your-alias>
   ```

2. **Deployment Failures**
   ```bash
   # Check deployment details
   sf project deploy report --job-id <job-id>
   
   # View detailed error messages
   sf project deploy report --job-id <job-id> --verbose
   ```

3. **Missing Dependencies**
   - Ensure Omniscript (OmniStudio) is installed in your org
   - Verify API version compatibility (project uses 59.0)

4. **Permission Issues**
   - Ensure you have "Customize Application" permission
   - Verify you can create Lightning Components and Visualforce Pages

### Check Deployment Status

```bash
# List recent deployments
sf project deploy list --target-org <your-org-alias>

# Get detailed deployment report
sf project deploy report --job-id <job-id> --verbose
```

## Additional Resources

- [Salesforce Extensions Documentation](https://developer.salesforce.com/tools/vscode/)
- [Salesforce CLI Setup Guide](https://developer.salesforce.com/docs/atlas.en-us.sfdx_setup.meta/sfdx_setup/sfdx_setup_intro.htm)
- [Salesforce DX Developer Guide](https://developer.salesforce.com/docs/atlas.en-us.sfdx_dev.meta/sfdx_dev/sfdx_dev_intro.htm)
- [Salesforce CLI Command Reference](https://developer.salesforce.com/docs/atlas.en-us.sfdx_cli_reference.meta/sfdx_cli_reference/cli_reference.htm)

## Project Configuration

The project configuration is defined in `sfdx-project.json`:
- **Package Directory**: `force-app` (default)
- **Source API Version**: 59.0
- **Namespace**: None (unmanaged package)

## Notes

- Test files (`__tests__/`) and configuration files (`jsconfig.json`, `.eslintrc.json`) are excluded from deployment via `.forceignore`
- The Lightning Web Component requires Omniscript runtime namespace (`omnistudio`)
- Visualforce page uses Box Content Uploader SDK version 25.2.0
