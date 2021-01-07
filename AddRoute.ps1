[CmdletBinding(DefaultParameterSetName='None')]
Param
(
    # Param1 help description
    [Parameter(Mandatory = $true)]
    $Network,
    #$NextHop = '100.69.197.253',

    [Parameter(Mandatory = $true)]
    $SubNet,

    [Parameter(Mandatory = $true)]
    $Gateway,
    
    [Switch]$Persistent,
    
    [string[]]
    $Computers = ( Get-Content 'C:\Users\fhadmin\Desktop\computers.txt' )

)

Begin
{

    [string]$routeString = 'Invoke-Expression "route'

    if ( $PSBoundParameters['Persistent'] ) {
        $routeString += ' -p'
    }
    $routeString += ' add {0} MASK {1} {2}"' -f $Network, $SubNet,$Gateway

    $scriptblock =  [scriptblock]::Create( $routeString )

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

                #Invoke-Command -ScriptBlock $test -ComputerName $c

                $tempresult = '' | Select-Object Computer,Result

                $tempresult.Computer = $c

                try {

                    $CommandResult = Invoke-Command -ScriptBlock $scriptblock -ComputerName $c -ErrorAction Stop

                    if ( [string]::IsNullOrEmpty( $CommandResult ) ) {

                        Write-Warning "No Results"

                        Write-Warning "Computer: $c"

                        Write-Warning "Command: $routeString"

                    }

                    $tempresult.Result = $CommandResult

                } catch {

                    $tempresult.Result = $_.Exception.Message

                }

                $tempresult

            } else {

                Write-Warning "Unable to connect to $c"

            }
    }

}
End
{

}



