<#
.Synopsis
   Checks whether a VM is utilizing Hyperthreading.
.DESCRIPTION
   Long description
.EXAMPLE
   Example of how to use this cmdlet
.EXAMPLE
   Another example of how to use this cmdlet
#>
function Get-HyperThreadingConfig
{
    [CmdletBinding()]
    Param
    (
        # Param1 help description
        [Parameter(ValueFromPipeline,ValueFromPipelineByPropertyName,Position=0)]
        [Alias('Computer')]
        [string[]]$ComputerName = $env:COMPUTERNAME
    )

    Begin
    {
        $params = "ComputerName","LogicalCPUs","PhysicalCPUs","Cores","HyperthreadingEnabled"
        Function Compare-CPUs($LogicalCPUs,$PhysicalCPUs){
            if($LogicalCPUs -gt $Physical) { 
                return $true 
            } else {
                return $false
            }
        }#Compare-CPUs
    }
    Process
    {
        foreach($computer in $ComputerName)
        {
            $Logical = 0
            $Physical = 0
            $Cores = 0
            $Sockets = 0
            $processors = [object[]]$(Get-WmiObject -Class win32_processor -ComputerName $computer)
            if($processors[0].NumberOfCores -eq $null)
            {
                Write-Verbose ( "{0}: Enumerating Older OS." -f $computer)
                $Sockets = New-Object hashtable
                $processors | foreach{
                    $Sockets[$_.SocketDesignation] = 1
                }
                $Physical = $Sockets.Count
                $Logical = $processors.Count
            }
            else
            {
                Write-Verbose ( "{0}: Processing Computer." -f $computer )
                $Cores = $processors.count
                $Logical = ($processors | Measure-Object NumberOfLogicalProcessors -Sum).sum
                $Physical = ($processors | Measure-Object Numberofcores -Sum).sum
            }
            $result = "" | select $params
            $result.ComputerName = $computer
            $result.LogicalCPUs  = $Logical
            $result.PhysicalCPUs = $Physical
            $result.Cores = $Cores
            $result.HyperthreadingEnabled = Compare-CPUs -LogicalCPUs $Logical -PhysicalCPUs $Physical
            $result
        }#FOREACH Computer
    }
    End
    {
    }
}


<#
# This Sample Code is provided for the purpose of illustration only and is not intended to be used in a production environment. THIS SAMPLE CODE AND ANY RELATED INFORMATION ARE PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS FOR A PARTICULAR PURPOSE. We grant You a nonexclusive, royalty-free right to use and modify the Sample Code and to reproduce and distribute the object code form of the Sample Code, provided that You agree: (i) to not use Our name, logo, or trademarks to market Your software product in which the Sample Code is embedded; (ii) to include a valid copyright notice on Your software product in which the Sample Code is embedded; and (iii) to indemnify, hold harmless, and defend Us and Our suppliers from and against any claims or lawsuits, including attorneys’ fees, that arise or result from the use or distribution of the Sample Code.</pre>
# Author: Amit Banerjee
 
# Purpose: Helps identify the number of physical processors, logical processors and hyperthreading on the server.
 
# Provide the computer information
 
$vComputerName = "."
 
$vLogicalCPUs = 0
 
$vPhysicalCPUs = 0
 
$vCPUCores = 0
 
$vSocketDesignation = 0
 
$vIsHyperThreaded = -1
 
# Get the Processor information from the WMI object
 
$vProcessors = [object[]]$(get-WMIObject Win32_Processor -ComputerName $vComputerName)
 
# To account for older machines
 
if ($vProcessors[0].NumberOfCores -eq $null)
 
{
 
$vSocketDesignation = new-object hashtable
 
$vProcessors |%{$vSocketDesignation[$_.SocketDesignation] = 1}
 
$vPhysicalCPUs = $vSocketDesignation.count
 
$vLogicalCPUs = $vProcessors.count
 
}
 
# If the necessary hotfixes are installed as mentioned below, then the NumberOfCores and NumberOfLogicalProcessors can be fetched correctly
 
else
 
{
 
# For any machine of Windows Server 2008 or above
 
# For Windows Server 2003, KB932370 needs to be installed
 
# For Windows XP, KB936235 needs to be installed
 
$vCores = $vProcessors.count
 
$vLogicalCPUs = $($vProcessors|measure-object NumberOfLogicalProcessors -sum).Sum
 
$vPhysicalCPUs = $($vProcessors|measure-object NumberOfCores -sum).Sum
 
}
 
# Additional code can be written here to input the data below into a database
 
"Logical CPUs: {0}; Physical CPUs: {1}; Number of Cores: {2}" -f $vLogicalCPUs,$vPhysicalCPUs,$vCores
 
if ($vLogicalCPUs -gt $vPhysicalCPUs)
 
{
 
"Hyperthreading: Active"
 
}
 
else
 
{
 
"Hyperthreading: Inactive"
 
}
#>