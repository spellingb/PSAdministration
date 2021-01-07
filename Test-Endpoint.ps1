function Test-Endpoint
{
    [CmdletBinding()]
    Param
    (
        $IP,
        $Port,
        $quiet,
        $Timeoutms = 1000
    )
    Begin
    {
        $ErrorActionPreference = 'stop'
        $return = $false

    }
    Process
    {

        Try{
            $t = New-Object Net.Sockets.TcpClient
            $res = $t.BeginConnect( $ip, $port, $null, $null)
            $wait = $res.AsyncWaitHandle.WaitOne($Timeoutms)
            if($wait){
                try {
                    $null = $t.endconnect($res)
                } catch {
                    Write-Verbose $($_.exception | Out-String)
                }
                if($quiet){
                    $return = $t.Connected
                } else {
                    $return = [pscustomobject][ordered]@{Name = $(-join ($ip,':',$port));IsConnected =  $t.Connected}
               }
            } else {
                $return = [pscustomobject][ordered]@{Name = $(-join ($ip,':',$port));IsConnected = "timed out"}
            }
        } catch {
            Write-Verbose $($_.exception)
            $return = [pscustomobject][ordered]@{Name = $(-join ($ip,':',$port));IsConnected = $false} 
        } finally {
            $t.Dispose()
        }
        return $return
    }
}# Test-Endpoint
