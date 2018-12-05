net use \\100.64.206.13\d$ /user:100.64.206.13\Administrator *

$logfile = "{0}\desktop\robocopy_{1}_.log" -f $env:USERPROFILE,$((get-date).tostring('ddmmyyThhMM'))
robocopy \\100.64.206.13\d$ d:\ /NOOFFLOAD /LOG:$logfile /ZB /Z /B /J /MT:16 /V

net use \\100.64.206.13\d$ /delete

$logfile = "{0}\desktop\robocopy_{1}_.log" -f $env:USERPROFILE,$((get-date).tostring('ddmmyyThhMM'))
$source = '\\100.64.206.13\d$'
$destination = 'd:\'


#Clear directory:
Get-ChildItem d:\ -Recurse | Remove-Item -Force

#Create 100GB as 1 file
$filestr = "D:\TestFile";$file = [io.file]::Create($filestr);$file.SetLength(50gb);$file.close()

#Create 100GB split into 10GB Files
1..10 | ForEach-Object{$filestr = "d:\10GBtest_$_";$file = [io.file]::Create($filestr);$file.SetLength(10gb);$file.close()}

#Create 100GB split into 1GB Files
1..20 | ForEach-Object{$filestr = "d:\1GBtest_$_";$file = [io.file]::Create($filestr);$file.SetLength(1gb);$file.close()}



#Define Variables first
$logfile = "{0}\desktop\robocopy_{1}_.log" -f $env:USERPROFILE,$((get-date).tostring('ddmmyyThhMM'))
$source = '\\100.64.206.13\d$'
$user = '100.64.206.13\Administrator'
$destination = 'd:\'

#Open File Share between servers:
Invoke-Expression ( "net use {0} /user:{1} *" -f $source,$user)

#Copy Command
Invoke-Expression ( "robocopy {0} {1} /tee /LOG:{2} /NOOFFLOAD /ZB /Z /B /J /MT:20 /V /ETA /R:5 /W:5" -f $source,$destination,$logfile )


#Close File share:
Invoke-Expression ( "net use {0} /delete" -f $source)

########################################
########################################
########################################
########################################

#Local File Transfer
$logfile = "{0}\desktop\robocopy_{1}_.log" -f $env:USERPROFILE,$((get-date).tostring('ddmmyyThhMM'))
$source = 'D:\Folder1'
$destination = 'D:\Folder2'
Invoke-Expression ( "robocopy {0} {1} /tee /LOG:{2} /NOOFFLOAD /ZB /Z /B /J /MT:20 /V /ETA /R:5 /W:5" -f $source,$destination,$logfile )

#Transfer from source:gen4phx1 to destination:gen34vm1 via L2L. Initiated from gen34vm1
$logfile = "{0}\desktop\robocopy_{1}_.log" -f $env:USERPROFILE,$((get-date).tostring('ddmmyyThhMM'))
$source = '\\100.64.206.13\d$'
$user = '100.64.206.13\Administrator'
$destination = 'd:\'
Invoke-Expression ( "net use {0} /user:{1} *" -f $source,$user)
Invoke-Expression ( "robocopy {0} {1} /tee /LOG:{2} /NOOFFLOAD /ZB /Z /B /J /MT:20 /V /ETA /R:5 /W:5" -f $source,$destination,$logfile )
Invoke-Expression ( "net use {0} /delete" -f $source)


#Transfer from source:gen4phx1 to destination:gen34vm1 via L2L. Initiated from gen4phx1
$logfile = "{0}\desktop\robocopy_{1}_.log" -f $env:USERPROFILE,$((get-date).tostring('ddmmyyThhMM'))
$source = 'd:\'
$user = '100.64.164.45\Administrator'
$destination = '\\100.64.164.45\d$'
Invoke-Expression ( "net use {0} /user:{1} *" -f $destination,$user)
Invoke-Expression ( "robocopy {0} {1} /tee /LOG:{2} /NOOFFLOAD /ZB /Z /B /J /MT:20 /V /ETA /R:5 /W:5" -f $source,$destination,$logfile )
Invoke-Expression ( "net use {0} /delete" -f $destination )


#Transfer from Source:gen34vm1 to destination:gen4phx1 via L2L. Initiated from gen4phx1
$logfile = "{0}\desktop\robocopy_{1}_.log" -f $env:USERPROFILE,$((get-date).tostring('ddmmyyThhMM'))
$destination = 'd:\'
$user = '100.64.164.45\Administrator'
$source = '\\100.64.164.45\d$'
Invoke-Expression ( "net use {0} /user:{1} *" -f $source,$user)
Invoke-Expression ( "robocopy {0} {1} /tee /LOG:{2} /NOOFFLOAD /ZB /Z /B /J /MT:20 /V /ETA /R:5 /W:5" -f $source,$destination,$logfile )
Invoke-Expression ( "net use {0} /delete" -f $source)

#Transfer from Source:gen34vm1 to destination:gen4phx1 via NAT. Initiated from gen4phx1
$logfile = "{0}\desktop\robocopy_{1}_.log" -f $env:USERPROFILE,$((get-date).tostring('ddmmyyThhMM'))
$destination = 'd:\'
$user = '147.75.0.100\Administrator'
$source = '\\147.75.0.100\d$'
Invoke-Expression ( "net use {0} /user:{1} *" -f $source,$user)
Invoke-Expression ( "robocopy {0} {1} /tee /LOG:{2} /NOOFFLOAD /ZB /Z /B /J /MT:20 /V /ETA /R:5 /W:5" -f $source,$destination,$logfile )
Invoke-Expression ( "net use {0} /delete" -f $source)








