Function Get-SqlServerKeys {
	<# 
	 .SYNOPSIS 
		Gets SQL Server Product Keys from local and remote SQL Servers. Works with SQL Server 2005-2014

	 .DESCRIPTION 
		Using a string of servers, a text file, or Central Management Server to provide a list of servers, this script will go to each server and get the product key for all installed instances. Clustered instances are supported as well. Requires regular user access to the SQL instances, SMO installed locally, Remote Registry enabled and acessible by the account running the script.

		Uses key decoder by Jakob Bindslet (http://goo.gl/1jiwcB)
		
	 .PARAMETER Servers
		A comma separated list of servers. This can be the NetBIOS name, IP, or SQL instance name

	 .EXAMPLE   
	 Get-SqlServerKeys winxp, sqlservera, sqlserver2014a, win2k8
		Gets SQL Server versions, editions and product keys for all instances within each server or workstation.

	#> 
	#Requires -Version 3.0
	[CmdletBinding(DefaultParameterSetName="Default")]

	Param(
		[parameter(Position=0)]
		[string[]]$Servers = $env:COMPUTERNAME
		)
		
	BEGIN 
    {
        Function Unlock-SQLServerKey {
			param(
				[Parameter(Mandatory = $true)]
				[byte[]]$data,
				[int]$version
			)
            Process
            {
                Write-Verbose "Version: $version"
                if($version -match "^(13|14)")
                {
                    Write-Verbose "Getting SQL 2016/2017 License."
                    try 
                    {
                        $Key = ($data)[0..66]
                        if ($version -ge 11) { $Keyoffset = 0 } else { $Keyoffset = 52 }
  
                        $isNKey = [int]($Key[14]/6) -bAND 1
                        $HF7 = 0xF7
                        $Key[14] = ($Key[14] -bAND $HF7) -bOR (($isNKey -bAND 2) * 4)
                        $i = 24
                        [String]$Chars = "BCDFGHJKMPQRTVWXY2346789"
  
                            do {
                                $Cur = 0 
                                $X = 14
                                do {
                                    $Cur = $Cur * 256    
                                    $Cur = $Key[$X + $Keyoffset] + $Cur
                                    $Key[$X + $Keyoffset] = [math]::Floor([double]($Cur/24))
                                    $Cur = $Cur % 24
                                    $X = $X - 1 
                                } while($X -ge 0)
                                $i = $i- 1
                                $KeyOutput = $Chars.SubString($Cur,1) + $KeyOutput
                                $last = $Cur
                            } while($i -ge 0)
  
                            $Keypart1 = $KeyOutput.SubString(1,$last)
                            $Keypart2 = $KeyOutput.Substring(1,$KeyOutput.length-1)
  
                            if($last -eq 0 ) {
                                $KeyOutput = "N" + $Keypart2
                            }
                            else {
                                $KeyOutput = $Keypart2.Insert($Keypart2.IndexOf($Keypart1)+$Keypart1.length,"N")
                            }
  
                            $a = $KeyOutput.Substring(0,5)
                            $b = $KeyOutput.substring(5,5)
                            $c = $KeyOutput.substring(10,5)
                            $d = $KeyOutput.substring(15,5)
                            $e = $KeyOutput.substring(20,5)
                            $productKey = $a + "-" + $b + "-"+ $c + "-"+ $d + "-"+ $e
                    } catch { 
                        $productKey = "Cannot decode product key." 
                    }
                }
                else
                {
                    Write-Verbose "Getting License for SQL 2012 and Below"
			        try {
			            if ($version -ge 11) { $binArray = ($data)[0..16] } else { $binArray = ($data)[52..66] }
				        $charsArray = "B","C","D","F","G","H","J","K","M","P","Q","R","T","V","W","X","Y","2","3","4","6","7","8","9"
				        for ($i = 24; $i -ge 0; $i--) {
					        $k = 0
					        for ($j = 14; $j -ge 0; $j--) {
						        $k = $k * 256 -bxor $binArray[$j]
						        $binArray[$j] = [math]::truncate($k / 24)
						        $k = $k % 24
					        }
					        $productKey = $charsArray[$k] + $productKey
					        if (($i % 5 -eq 0) -and ($i -ne 0)) {
						        $productKey = "-" + $productKey
					        }
				        }
			        } catch { 
                        $productkey = "UNAVAILABLE" 
                    }
                }
                Write-Verbose "Returning ProductKey: $productKey"
			    return $productKey
            }
		} # Function Unlock-SQLServerKey
        Function Get-SQLVersionName($sqlversionnumber) {
            switch -regex ($sqlversionnumber)
            {
                "^10\.0" {'SQL Server 2008'}
                "^10\.5" {'SQL Server 2008 R2'}
                "^11\." {'SQL Server 2012'}
                "^12\." {'SQL Server 2014'}
                "^13\." {'SQL Server 2016'}
                "^14\." {'SQL Server 2017'}
            }
        } # Function Get-SQLVersionName
        Function Get-Instances($Regkey) {
            $Regkey.opensubkey("SOFTWARE\Microsoft\Microsoft SQL Server\Instance Names\SQL", $false)
        } #Function Get-Instances
        Function Get-SQLInstanceSubkeys($RegKey,$instance){
            
            $InstanceData = $RegKey.opensubkey("SOFTWARE\Microsoft\Microsoft SQL Server\$instance\Setup", $false)
            $keyreturn =  New-Object psobject @{
                Instance = $instance.Split('.')[1]
                Version = $InstanceData.getvalue('Version')
                Edition = $InstanceData.getvalue('Edition')
                DigPID  = "" #$InstanceData.getvalue('DigitalProductID')
            }
            $keyreturn.DigPID = switch -regex ($keyreturn.Version)
                {
                    "^1(0|1|2)\." {$InstanceData.getvalue('DigitalProductID')}
                    "^1(3|4)\." 
                        {
                            $version = $keyreturn.Version.split('.')[0]
                            $InstanceData = $RegKey.opensubkey("SOFTWARE\Microsoft\Microsoft SQL Server\$($version)0\Tools\ClientSetup")
                            $InstanceData.getvalue('DigitalProductID')
                        }
                }
            return $keyreturn
        } #Function Get-SQLInstanceSubKeys
        Function New-SqlInstanceObject ($ComputerName,$InstanceData) {
            $object = "" | select 'ComputerName','SQL Instance','SQL Version Name','Product Key'
            $object."Computername" = $ComputerName
			$object."SQL Instance" = if($InstanceData.Instance -eq "MSSQLSERVER"){"{0} (default)"-f $InstanceData.Instance}else{$InstanceData.Instance}
            $object.'SQL Version Name' = -join ($(Get-SQLVersionName -sqlversionnumber $InstanceData.Version),' ', $InstanceData.Edition," ($($InstanceData.Version))")
			$object."Product Key" = if($InstanceData.edition -match "(Express|Developer)"){
                       "N/A" 
                    } else { 
                        Unlock-SQLServerKey -data $instancedata.DigPID -version $instancedata.Version.Split('.')[0]
                    }
            return $object
        } # Function New-SQLInstanceObject
	}

	PROCESS {
		if ((Get-Host).Version.Major -lt 3) { throw "PowerShell 3.0 and above required." }

		foreach ($servername in $servers) {
			$servername = $servername.Split("\")[0]

			if ($servername -eq "." -or $servername -eq "localhost" -or $servername -eq $env:computername) {
				$localmachine = [Microsoft.Win32.RegistryHive]::LocalMachine
				$defaultview = [Microsoft.Win32.RegistryView]::Default
				$reg = [Microsoft.Win32.RegistryKey]::OpenBaseKey($localmachine,$defaultview)
			} else {
				# Get IP for remote registry access. It's the most reliable.
				try { 
                    $ipaddr = ([System.Net.Dns]::GetHostAddresses($servername)).IPAddressToString 
                
                } catch { 
                    Write-Warning "Can't resolve $servername. Moving on."
                    continue 
                }

				try {
					$reg = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey("LocalMachine", $ipaddr)	
				} catch { 
                    Write-Warning "Can't access registry for $servername. Is the Remote Registry service started?"
                    continue 
                }
			}

			$Instances = Get-Instances $reg

			if ($instances -eq $null) { 
                Write-Warning "No instances found on $servername. Moving on."
                continue 
            }

			# Get Product Keys for all instances on the server.
			foreach ($instance in $instances.GetValueNames()) {
                $sqlserverinstance = $instances.getvalue($instance)
                $instancedata = Get-SQLInstanceSubkeys -RegKey $reg -instance $sqlserverinstance
                New-SqlInstanceObject -ComputerName $servername -InstanceData $instancedata
			}
			$reg.Close()
		}#Foreach Servername
	}

}
