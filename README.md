# VSTS Extensions

## Prerequisites

- Install Azure Powershell - https://github.com/Azure/azure-powershell#installation
- Install the VSTS CLI - https://github.com/Microsoft/vsts-cli
- Access to an Azure Service Account

## Build

VSTS requires build tasks to be installed via a VSIX. To build the VSIX run the following:

### App Service Diagnostics Logs

```console
tfx extension create --manifest-globs vss-extensions-appservicediagnosticslogs.json
```

### Create CosmosDB

```console
tfx extension create --manifest-globs vss-extensions-ensurecosmosdbdatabase.json
```