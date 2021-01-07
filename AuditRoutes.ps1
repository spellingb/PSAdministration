

[CmdletBinding(DefaultParameterSetName='None')]
Param
(
    # Param1 help description
    [Parameter(ParameterSetName = 'NextHop')]
    $NextHop,
    #$NextHop = '100.69.197.253',

    [Parameter(ParameterSetName = 'DestinationPrefix')]
    $DestinationPrefix,

    [ValidateSet('ActiveStore','PersistentStore')]
    [string]$PolicyStore = 'ActiveStore',

    # Param2 help description
    [string[]]
    $Computers = ( Get-Content 'C:\Users\fhadmin\Desktop\computers.txt' ),

    [switch]
    $ExporttoCSV
)

Begin
{

    $Return = @()

    $params = @{
        AddressFamily = 'IPv4'
        ErrorAction = 'SilentlyContinue'
    }

    if ( $PSBoundParameters['NextHop'] ) {
        $params['Nexthop'] = $NextHop
    }

    if ( $PSBoundParameters['PolicyStore'] ) {
        $params['PolicyStore'] = $PolicyStore
    }

    if ( $PSBoundParameters['DestinationPrefix'] ) {
        $params['DestinationPrefix'] = $DestinationPrefix
    }

    $scriptblock =  [scriptblock]::Create( @"

    param ( `$Params )

    &{

        Get-NetRoute @params | 

            Select-Object DestinationPrefix,NextHop,RouteMetric,InterfaceAlias,TypeOfRoute,Store

    } @psboundparameters
"@ )

    Function Test-RemoteConnection ( $Conn ) {

        Try {

            if ( $Conn -match $env:COMPUTERNAME ) {

                return $true

            } else {

                Invoke-Command -ScriptBlock {$true} -ComputerName $Conn -ea stop

            }


        } catch {

            return $false

        }

    }

}
Process
{
    foreach ($c in $computers ) {

            if ( Test-RemoteConnection $c ) {

                $command = Invoke-Command -ScriptBlock $scriptblock -ComputerName $c -ArgumentList $params

                if ( [string]::IsNullOrEmpty( $command ) ) {

                    Write-Warning "No Routes found matching Parameter: $Route"

                } else {

                    $Return += $command

                    $command

                }

            } else {

                Write-Warning "Unable to connect to $c"

            }
    }

}
End
{

    if ( $ExporttoCSV ) {

        $Exportpath = "$home\desktop\RouteAudit.csv"

        $Return | Export-Csv -Path $Exportpath -Force -NoTypeInformation

    }
}



