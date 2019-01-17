#defines the machine name or IP address to remote into#
$global:machinename = "phx01-jp02.firehost.net";
#defines the window title. Remote Desktop Connection is the default#
$global:app = "Remote Desktop Connection";
#defines the wait time to pause for login credentials#
$global:loginWait = 180;
#defnies the wait time between mouse movements#
$global:loopWait = 30;
#defines the number of mouse movements before the session is closed and re-started#
$global:loopLength = 960;
#defines the minimum ammount of pixels to move the mouse#
$global:moveMin = 10;
#defines the minimum ammount of pixels to move the mouse#
$global:moveMax = 50;

$global:reload = 0;
$global:r = $null;
$global:w = $null;
$global:h = $null;
$global:p = $null;
$global:t = $null;


Add-PSSnapin WASP;

[void] [System.Reflection.Assembly]::LoadWithPartialName("System.Drawing");
[void] [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms");

Add-Type @"
  using System;
  using System.Runtime.InteropServices;
  public class SFW {
     [DllImport("user32.dll")]
     [return: MarshalAs(UnmanagedType.Bool)]
     public static extern bool SetForegroundWindow(IntPtr hWnd);
  }
"@ -ErrorAction SilentlyContinue

$Win32ShowWindowAsync = Add-Type –memberDefinition @” 
    [DllImport("user32.dll")] 
    public static extern bool ShowWindowAsync(IntPtr hWnd, int nCmdShow);
“@ -name “Win32ShowWindowAsync” -namespace Win32Functions –passThru

function Test-KeyPress{ 
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.Windows.Forms.Keys[]]
        $Keys
    )
    
    $Signature = @'
    [DllImport("user32.dll", CharSet=CharSet.Auto, ExactSpelling=true)] 
    public static extern short GetAsyncKeyState(int virtualKeyCode); 
'@
    $API = Add-Type -MemberDefinition $Signature -Name 'Keypress' -Namespace Keytest -PassThru
    
    $Result = foreach ($Key in $Keys)
    {
        [bool]($API::GetAsyncKeyState($Key) -eq -32767)
    }
    
    $Result -notcontains $false
}

function Title{
    Echo ""
    Echo "################################################################################"
    Echo "################################################################################"
    Echo "##                                                                            ##"
    Echo "##                                                                            ##"
    Echo "##                   Remote Desktop Connector with Keep Alive                 ##"
    Echo "##                                                                            ##"
    Echo "##                               By Curtis Siemens                            ##"
    Echo "##                                                                            ##"
    Echo "##                                                                            ##"
    Echo "################################################################################"
    Echo "################################################################################"        
    Echo ""
}

function Init{
    Echo "Starting Remote Desktop Connection to $global:machinename";
    Start-Process "$env:windir\system32\mstsc.exe" -ArgumentList "/v:$global:machinename";
    Echo "Process started!";
    Echo "";
    start-sleep -s 5;

    Echo "Getting process handle...";
    $global:r = select-window -title *$global:app*;
    $global:w = $global:r | select-object -first 1;
    $global:h = $global:w.handle;
    $global:p = $global:w.processid;
    $global:t = $global:w.title;

    if (!$global:h) {
        "ERROR: $global:app got null handle.";
        continue;
    }
    Else {
        Echo "Handle captured!";
        Echo "";
        Echo "Details -";
        Echo "Application: $global:app";
        Echo "Handle: $global:h";
        Echo "Process: $global:p";
        Echo "Title: $global:t";
        Echo "";
    }
    Echo "";
    Start-Sleep -s $global:loginWait;
}


function TearDown{
    Echo "Tearing down session...";
    Stop-Process $global:p;
    If ($global:reload = 1){
        StartOver;
    }
}

function Loop{
    $Stop = $null;
    $Count = 0;
    Do  {
        $Count++;
        $Pos = [System.Windows.Forms.Cursor]::Position;
        $Xy = Get-Random -Minimum 1 -Maximum 100;
        $Move = Get-Random -Minimum $global:moveMin -Maximum $global:moveMax;
        Echo "Checking for active window and foreground position...";
        [SFW]::SetForegroundWindow($global:h);
        $Win32ShowWindowAsync::ShowWindowAsync($global:h, 3) | Out-Null;
        Echo "";
        If ($Xy -gt 75 -and $Xy -lt 100) {
            [System.Windows.Forms.Cursor]::Position = New-Object System.Drawing.Point((($Pos.X) + $Move), $Pos.Y);
            Echo "Moving mouse right $Move pixels.";
        }
        ElseIf ($Xy -gt 50 -and $Xy -lt 75){
            [System.Windows.Forms.Cursor]::Position = New-Object System.Drawing.Point(($Pos.X), ($Pos.Y + $Move));
            Echo "Moving mouse down $Move pixels.";
        }
        ElseIf ($Xy -gt 25 -and $Xy -lt 50){
            [System.Windows.Forms.Cursor]::Position = New-Object System.Drawing.Point(($Pos.X), ($Pos.Y - $Move));
            Echo "Moving mouse up $Move pixels.";
        }
        ElseIf ($Xy -lt 25){
            [System.Windows.Forms.Cursor]::Position = New-Object System.Drawing.Point((($Pos.X) - $Move), $Pos.Y);
            Echo "Moving mouse left $Move pixels.";
        }
        Echo "The mouse has been moved $Count times.";
        If ($Count -gt $global:loopLength){
            $Stop = 1;
            $global:reload = 1;
            Echo "";
            Echo "Maximum loop lenth reached.";
        }   
        If (Test-KeyPress -Keys ControlKey){
            $Stop = 1;
            Echo "";
            Echo "CTRL key detected! Setting stop flag.";
        }
        Echo "";
        Start-sleep -s $global:loopWait;
    } While (!$Stop)
    Echo "";
    Echo "Automation ended!";
    TearDown;
}

function StartOver{
    Title;
    Init;
    Loop;
}

StartOver;