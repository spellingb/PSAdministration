Function Convert-MachineKeyName($fileobject){
    if(!$fileobject){
        $filename = ls "C:\ProgramData\Microsoft\Crypto\RSA\MachineKeys"
    } else {$filename = $fileobject }
    foreach($file in $filename)
    {
        try{
        $bytes = [system.io.file]::ReadAllBytes($file.fullname)
        $ContainerName = [System.Text.Encoding]::ASCII.GetString($bytes, 40, $bytes[8]-1)
        } Catch{
        $ContainerName="No read access"
        }
        $tmp = "" | select Container,FileName
        $tmp.Container = $ContainerName
        $tmp.FileName = $file.name
        $tmp
    }
}



Function get-mkn{
Param(
[Parameter(ValueFromPipeline=$true)]$file,
$ShowFailed
)
    Begin {
        $ErrorActionPreference = 'stop'
        if(!$file){
            $filename = Get-ChildItem C:\programdata\Microsoft\Crypto\RSA\MachineKeys | select -ExpandProperty fullname
        }elseif($file.gettype() -eq $([System.IO.FileInfo])) {
            $filename = $file.fullname
        } else {
            $filename = $file
        }
    }
    Process
    {
        foreach($fn in $filename)
        {
            Try{
                $bytes = [system.io.file]::ReadAllBytes($fn)
                $container = [System.Text.Encoding]::ASCII.GetString($bytes, 40, $bytes[8]-1)
                if($container -match "^({[a-f0-9]{8}|[a-f0-9]{8})-([a-f0-9]{4}-){3}[a-f0-9]{12}" ) {
                    if($ShowFailed){ Write-Host -F Yellow $container }
                } else {
                    New-Object psobject -Property @{Name=$container.split('_')[0];Path = $fn}
                }
            } catch {
                if($ShowFailed){ Write-Host -f Red "$fn - No read access"}
            }
        }
    }
}