using namespace System.Net

# Input bindings are passed in via param block.
param($Request, $TriggerMetadata)
Connect-AzAccount
# Map input bindings to variables
$TableName = $Request.Body.TableName
$WorkspaceId = $Request.Body.WorkspaceId

# Essentially a copy+paste of https://github.com/javiersoriano/sentinel-scripts/blob/main/ADX/Create-TableInADX.ps1
$query = $TableName + ' | getschema | project ColumnName, DataType'
$output = (Invoke-AzOperationalInsightsQuery -WorkspaceId $WorkspaceId -Query $query).Results

$TableExpandFunction = $TableName + 'Expand'
$TableRaw = $TableName + 'Raw'
$RawMapping = $TableRaw + 'Mapping'

$FirstCommand = @()
$ThirdCommand = @()

foreach ($record in $output) {
    if ($record.DataType -eq 'System.DateTime') {
        $dataType = 'datetime'
        $ThirdCommand += $record.ColumnName + " = todatetime(events." + $record.ColumnName + "),"
    } else {
        $dataType = 'string'
        $ThirdCommand += $record.ColumnName + " = tostring(events." + $record.ColumnName + "),"
    }
    $FirstCommand += $record.ColumnName + ":" + "$dataType" + ","    
}

$schema = ($FirstCommand -join '') -replace ',$'
$function = ($ThirdCommand -join '') -replace ',$'

$CreateRawTable = @'
.create table {0} (Records:dynamic)
'@ -f $TableRaw

$CreateRawMapping = @'
.create table {0} ingestion json mapping '{1}' '[{{"column":"Records","Properties":{{"path":"$.records"}}}}]'
'@ -f $TableRaw, $RawMapping

$CreateRetention = @'
.alter-merge table {0} policy retention softdelete = 0d
'@ -f $TableRaw

$CreateTable = @'
.create table {0} ({1})
'@ -f $TableName, $schema

$CreateFunction = @'
.create-or-alter function {0} {{
    {1}
| mv-expand events = Records
| project 
{2}
}}
'@ -f $TableExpandFunction, $TableRaw, $function

$CreatePolicyUpdate = @'
.alter table {0} policy update @'[{{"Source": "{1}", "Query": "{2}()", "IsEnabled": "True", "IsTransactional": true}}]'
'@ -f $TableName, $TableRaw, $TableExpandFunction

# Create a JSON object to return to the caller
$body = @{
    "CreateRawTable" = $CreateRawTable
    "CreateRawMapping" = $CreateRawMapping
    "CreateRetention" = $CreateRetention
    "CreateTable" = $CreateTable
    "CreateFunction" = $CreateFunction
    "CreatePolicyUpdate" = $CreatePolicyUpdate
}

# Associate values to output bindings by calling 'Push-OutputBinding'.
Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
    StatusCode = [HttpStatusCode]::OK
    Body = $body
})
