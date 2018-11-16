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
