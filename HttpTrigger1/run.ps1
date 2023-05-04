using namespace System.Net

# Input bindings are passed in via param block.
param($Request, $TriggerMetadata)




# Write to the Azure Functions log stream.
Write-Host "PowerShell HTTP trigger function processed a request."


#az login --identity
#$FunctionApps = az functionapp list | ConvertFrom-Json
#$FunctionApps.Name

$eventHubsNamespacesResourceId = '/subscriptions/0d72a622-0326-432f-bb64-8f7dba37fa5e/resourceGroups/temp1/providers/Microsoft.EventHub/namespaces/eventhubtemp'
New-AzOperationalInsightsDataExport -ResourceGroupName temp1 -WorkspaceName loganalytemp -DataExportName 'ruleName' -TableName 'SecurityEvent,Heartbeat' -ResourceId $eventHubsNamespacesResourceId



