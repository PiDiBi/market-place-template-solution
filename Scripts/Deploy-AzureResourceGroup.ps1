#Requires -Version 3.0
#Requires -Module AzureRM.Resources
#Requires -Module Azure.Storage

Param(
    [string] $ResourceGroupLocation = 'northeurope',
    [string] $ResourceGroupName = 'gordicamprg008',
    [string] $StorageAccountName = 'gordicamp',
    [string] $StorageContainerName = 'public', #gordicamp/public/* -- no need to use SAS, resource group: gordisource
    [string] $TemplateFile = '..\_publish\mainTemplate.json',
    [string] $TemplateParametersFile = '..\_publish\mainTemplate.parameters.json',
    [string] $ArtifactStagingDirectory = '..\_publish'
)

Import-Module Azure -ErrorAction SilentlyContinue

try {
    [Microsoft.Azure.Common.Authentication.AzureSession]::ClientFactory.AddUserAgent("VSAzureTools-$UI$($host.name)".replace(" ","_"), "2.9")
} catch { }

Set-StrictMode -Version 3

$OptionalParameters = New-Object -TypeName Hashtable
$TemplateFile = [System.IO.Path]::GetFullPath([System.IO.Path]::Combine($PSScriptRoot, $TemplateFile))
$TemplateParametersFile = [System.IO.Path]::GetFullPath([System.IO.Path]::Combine($PSScriptRoot, $TemplateParametersFile))

# copy to staging directory
Copy-Item -Path '..\Templates\' -Filter *.json -Destination $ArtifactStagingDirectory –Recurse
Copy-Item -Path '..\Scripts\' -Filter *.ps1 -Destination $ArtifactStagingDirectory –Recurse

# Convert relative paths to absolute paths if needed
$ArtifactStagingDirectory = [System.IO.Path]::GetFullPath([System.IO.Path]::Combine($PSScriptRoot, $ArtifactStagingDirectory))

Set-Variable ArtifactsLocationName 'templateBaseUrl' -Option ReadOnly -Force
Set-Variable LocationParameterName 'location' -Option ReadOnly -Force

$OptionalParameters.Add($ArtifactsLocationName, $null)
$OptionalParameters.Add($LocationParameterName, $null)

# Parse the parameter file and update the values of artifacts location and artifacts location SAS token if they are present
$JsonContent = Get-Content $TemplateParametersFile -Raw | ConvertFrom-Json
$JsonParameters = $JsonContent | Get-Member -Type NoteProperty | Where-Object {$_.Name -eq "parameters"}

if ($JsonParameters -eq $null) {
    $JsonParameters = $JsonContent
}
else {
    $JsonParameters = $JsonContent.parameters
}

$JsonParameters | Get-Member -Type NoteProperty | ForEach-Object {
    $ParameterValue = $JsonParameters | Select-Object -ExpandProperty $_.Name

    if ($_.Name -eq $ArtifactsLocationName -or $_.Name -eq $LocationParameterName) {
        $OptionalParameters[$_.Name] = $ParameterValue.value
    }
}

   
$StorageAccountContext = (Get-AzureRmStorageAccount | Where-Object{$_.StorageAccountName -eq $StorageAccountName}).Context

# Generate the value for artifacts location if it is not provided in the parameter file
$ArtifactsLocation = $OptionalParameters[$ArtifactsLocationName]
if ($ArtifactsLocation -eq $null) {
    $ArtifactsLocation = $StorageAccountContext.BlobEndPoint + $StorageContainerName
    $OptionalParameters[$ArtifactsLocationName] = $ArtifactsLocation # _baseLocation
}

# Copy files from the local storage staging location to the storage account container
New-AzureStorageContainer -Name $StorageContainerName -Context $StorageAccountContext -Permission Container -ErrorAction SilentlyContinue *>&1

$ArtifactFilePaths = Get-ChildItem $ArtifactStagingDirectory -Recurse -File | ForEach-Object -Process {$_}
foreach ($Source in $ArtifactFilePaths) {
	$SourcePath = $Source.FullName #.Substring($ArtifactStagingDirectory.length + 1)
    $BlobName = $Source.Name
    Set-AzureStorageBlobContent -File $SourcePath -Blob $BlobName -Container $StorageContainerName -Context $StorageAccountContext -Force
}

$OptionalParameters[$LocationParameterName] = $ResourceGroupLocation        

# Create or update the resource group using the specified template file and template parameters file
New-AzureRmResourceGroup -Name $ResourceGroupName -Location $ResourceGroupLocation -Verbose -Force -ErrorAction Stop 

New-AzureRmResourceGroupDeployment -Name ((Get-ChildItem $TemplateFile).BaseName + '-' + ((Get-Date).ToUniversalTime()).ToString('MMdd-HHmm')) `
                                   -ResourceGroupName $ResourceGroupName `
                                   -TemplateFile $TemplateFile `
                                   -TemplateParameterFile $TemplateParametersFile `
                                   @OptionalParameters `
                                   -Force -Verbose

