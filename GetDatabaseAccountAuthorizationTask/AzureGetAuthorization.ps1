Trace-VstsEnteringInvocation $MyInvocation
Import-VstsLocStrings "$PSScriptRoot\Task.json"

$latestVersion = 

# Get inputs.

$databaseName = Get-VstsInput -Name databaseName
$resourcegroupName = Get-VstsInput -Name resourcegroupName
$outputCosmosDbUri = Get-VstsInput -Name outputCosmosDbUri
$outputCosmosDbAccessKey = Get-VstsInput -Name outputCosmosDbAccessKey

$__vsts_input_errorActionPreference = "stop"
$__vsts_input_failOnStandardError = $true
$targetAzurePs = "LatestVersion"
#$customTargetAzurePs = Get-VstsInput -Name CustomTargetAzurePs
# Validate the script path and args do not contains new-lines. Otherwise, it will
# break invoking the script via Invoke-Expression.

$script = "Invoke-AzureRmResource"
$scriptArguments = "-Action listKeys -ResourceType 'Microsoft.DocumentDb/databaseAccounts' -ApiVersion '2015-04-08' -ResourceGroupName $resourcegroupName -Name $databaseName"

if ($targetAzurePs -eq $otherVersion) {
    if ($customTargetAzurePs -eq $null) {
        throw (Get-VstsLocString -Key InvalidAzurePsVersion $customTargetAzurePs)
    } else {
        $targetAzurePs = $customTargetAzurePs.Trim()        
    }
}
$pattern = "^[0-9]+\.[0-9]+\.[0-9]+$"
$regex = New-Object -TypeName System.Text.RegularExpressions.Regex -ArgumentList $pattern

if ($targetAzurePs -eq $latestVersion) {
    $targetAzurePs = ""
} elseif (-not($regex.IsMatch($targetAzurePs))) {
    throw (Get-VstsLocString -Key InvalidAzurePsVersion -ArgumentList $targetAzurePs)
}
. "$PSScriptRoot\Utility.ps1"

$targetAzurePs = Get-RollForwardVersion -azurePowerShellVersion $targetAzurePs
$authScheme = ''

try
{
    $serviceNameInput = Get-VstsInput -Name ConnectedServiceNameSelector -Default 'ConnectedServiceName'
    $serviceName = Get-VstsInput -Name $serviceNameInput -Default (Get-VstsInput -Name DeploymentEnvironmentName)
    if (!$serviceName)
    {
            Get-VstsInput -Name $serviceNameInput -Require
    }
    $endpoint = Get-VstsEndpoint -Name $serviceName -Require
    if($endpoint)
    {
        $authScheme = $endpoint.Auth.Scheme 
    }
     Write-Verbose "AuthScheme $authScheme"
}
catch
{
   $error = $_.Exception.Message
   Write-Verbose "Unable to get the authScheme $error" 
}

Update-PSModulePathForHostedAgent -targetAzurePs $targetAzurePs -authScheme $authScheme

try {
    # Initialize Azure.
    Import-Module $PSScriptRoot\ps_modules\VstsAzureHelpers_
    Initialize-Azure -azurePsVersion $targetAzurePs -strict

    # Trace the expression as it will be invoked.

	
    $scriptCommand = "& '$($script.Replace("'", "''"))' $scriptArguments"


    # Remove all commands imported from VstsTaskSdk, other than Out-Default.
    # Remove all commands imported from VstsAzureHelpers_.
    Get-ChildItem -LiteralPath function: |
        Where-Object {
            ($_.ModuleName -eq 'VstsTaskSdk' -and $_.Name -ne 'Out-Default') -or
            ($_.Name -eq 'Invoke-VstsTaskScript') -or
            ($_.ModuleName -eq 'VstsAzureHelpers_' )
        } |
        Remove-Item



    # For compatibility with the legacy handler implementation, set the error action
    # preference to continue. An implication of changing the preference to Continue,
    # is that Invoke-VstsTaskScript will no longer handle setting the result to failed.
    $global:ErrorActionPreference = 'Continue'

    # Undocumented VstsTaskSdk variable so Verbose/Debug isn't converted to ##vso[task.debug].
    # Otherwise any content the ad-hoc script writes to the verbose pipeline gets dropped by
    # the agent when System.Debug is not set.

    $global:__vstsNoOverrideVerbose = $true



    # Run the user's script. Redirect the error pipeline to the output pipeline to enable

    # a couple goals due to compatibility with the legacy handler implementation:

    # 1) STDERR from external commands needs to be converted into error records. Piping

    #    the redirected error output to an intermediate command before it is piped to

    #    Out-Default will implicitly perform the conversion.

    # 2) The task result needs to be set to failed if an error record is encountered.

    #    As mentioned above, the requirement to handle this is an implication of changing

    #    the error action preference.

    ([scriptblock]::Create($scriptCommand)) | 

        ForEach-Object {
            Remove-Variable -Name scriptCommand
            Write-Host "##[command]$_"
            . $_ 2>&1
        } | 

        ForEach-Object {
            if($_ -is [System.Management.Automation.ErrorRecord]) {
                if($_.FullyQualifiedErrorId -eq "NativeCommandError" -or $_.FullyQualifiedErrorId -eq "NativeCommandErrorMessage") {
                    ,$_
                    if($__vsts_input_failOnStandardError -eq $true) {
                        "##vso[task.complete result=Failed]"
                    }
                }
                else {
                    if($__vsts_input_errorActionPreference -eq "continue") {
                        ,$_
                        if($__vsts_input_failOnStandardError -eq $true) {
                            "##vso[task.complete result=Failed]"
                        }
                    }
                    elseif($__vsts_input_errorActionPreference -eq "stop") {
                        throw $_
                    }
                }
            } else {

                ,$_
            }
        }

        if(-not [string]::IsNullOrEmpty($outputCosmosDbUri))
        {
            $endpointuri = "https://$databasename.documents.azure.com:443/"
            Write-Host "##vso[task.setvariable variable=$outputCosmosDbUri;]$endpointuri"
        }
        if(-not [string]::IsNullOrEmpty($outputCosmosDbAccessKey))
        {
            $masterAccessKey = "Nochnix drin"
            Write-Host "##vso[task.setvariable variable=$outputCosmosDbAccessKey;]$masterAccessKey"
        }

}

finally {

    if ($__vstsAzPSInlineScriptPath -and (Test-Path -LiteralPath $__vstsAzPSInlineScriptPath) ) {
        Remove-Item -LiteralPath $__vstsAzPSInlineScriptPath -ErrorAction 'SilentlyContinue'
    }

    Import-Module $PSScriptRoot\ps_modules\VstsAzureHelpers_
    Remove-EndpointSecrets
}