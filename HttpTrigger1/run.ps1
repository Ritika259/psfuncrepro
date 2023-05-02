using namespace System.Net

# Input bindings are passed in via param block.
param($Request, $TriggerMetadata)




# Write to the Azure Functions log stream.
Write-Host "PowerShell HTTP trigger function processed a request."


az login --identity
$FunctionApps = az functionapp list | ConvertFrom-Json
$FunctionApps.Name



