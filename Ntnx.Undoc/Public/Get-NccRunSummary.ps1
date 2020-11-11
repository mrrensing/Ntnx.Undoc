function Get-NccRunSummary {   
<#
.SYNOPSIS
Dynamically Generated API Function
.NOTES
NOT FOR PRODUCTION USE - FOR DEMONSTRATION/EDUCATION PURPOSES ONLY

The code samples provided here are intended as standalone examples.  They can be downloaded, copied and/or modified in any way you see fit.

Please be aware that all code samples provided here are unofficial in nature, are provided as examples only, are unsupported and will need to be heavily modified before they can be used in a production environment.
#>

    [CmdletBinding()]
    [OutputType()]

    param(
        # VIP or FQDN of target AOS cluster
        [Parameter(Mandatory=$true)]
        [string]
        $ComputerName,

        # Prism UI Credential to invoke call
        [Parameter(Mandatory=$true)]
        [PSCredential]
        $Credential,

        # Output results in Hash Table format
        [Parameter(Mandatory=$false)]
        [switch]
        $HashTable,

        # Output results in flattened output
        [Parameter(Mandatory=$false)]
        [switch]
        $SimpleOutput,

        # Port (Default is 9440)
        [Parameter(Mandatory=$false)]
        [int16]
        $Port = 9440
    )

    process {
        $body = [Hashtable]::new()
        #$body.add("BodyParam1",$BodyParam1)

        $iwrArgs = @{
            Uri = "https://$($ComputerName):$($Port)/PrismGateway/services/rest/v1/ncc/run_summary?detailedSummary=true"
            Method = "GET"
            ContentType = "application/json"
        }
        if($body.count -ge 1){
            $iwrArgs.add("Body",($body | ConvertTo-Json))
        }

        if($PSVersionTable.PSVersion.Major -lt 6){
            $basicAuth = Initialize-BasicAuthHeader -credential $Credential
            $iwrArgs.Add("headers",$basicAuth)
        }
        else{
            $iwrArgs.add("Authentication","Basic")
            $iwrArgs.add("Credential",$Credential)
            $iwrArgs.add("SkipCertificateCheck",$null)
            $iwrArgs.add("SslProtocol","Tls12")
        }
        
        $response = Invoke-WebRequest @iwrArgs

        if($response.StatusCode -in 200..204){
            $jsonArgs = [hashtable]::new()
            $jsonArgs.add('Depth',99)
            if($HashTable){
                $jsonArgs.add('AsHashtable',$true)
            }
            if($SimpleOutput){
                $responseAlt = foreach($r in ($response.Content | ConvertFrom-Json @jsonArgs)){
                    $propList = $r.entityType
                    foreach($p in $propList){
                        $r.entityType.$p | Add-Member -NotePropertyName "EntityType" -NotePropertyValue $r.domainType
                        $r.entityType.$p | Add-Member -NotePropertyName "ComputerName" -NotePropertyValue $ComputerName
                        $r.componentFaultToleranceStatus.$p
                    }
                }
                Write-Output $responseAlt
            }
            else{
                $response.Content | ConvertFrom-Json @jsonArgs
            }
        }
        elseif($response.StatusCode -eq 401){
            Write-Verbose -Message "Credential used not authorized, exiting..."
            Write-Error -Message "$($response.StatusCode): $($response.StatusDescription)"
            exit
        }
        else{
            Write-Error -Message "$($response.StatusCode): $($response.StatusDescription)"
        }    

    }
                
}
