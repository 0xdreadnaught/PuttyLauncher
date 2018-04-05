# Command line arguments
[CmdletBinding()]
param([Parameter(Position=0)][string]$op = "",
      [string]$uid = "",
      [switch]$nocreds
     )

# Script path
$binPath = $(Split-Path $MyInvocation.MyCommand.Path)
$batchPath = Split-Path $binPath

# Config vars
$putty = "C:\Program Files (x86)\PuTTY\putty.exe"

# Session information import
$connections = Import-Csv $binPath\connections.csv

# Handle batch creation operation
if ($op -eq "batch") {
    
    # Remove existing site folders
    Write-Host "Removing existing batch folders... " -NoNewline

    Get-ChildItem $batchPath | ForEach-Object {
        if ($_.FullName -ne $binPath) {
            Remove-Item -Recurse $_.FullName > $null
        }
    }
    
    Write-Host "Done"
    
    # Create site folders and nested NoCreds folders
    Write-Host "Creating new site folders... " -NoNewline
	New-Item -ItemType Directory "$batchPath\Assigned" > $null
	New-Item -ItemType Directory "$batchPath\Assigned\NoCreds" > $null
    $connections.SITE | Get-Unique | ForEach-Object {
        New-Item -ItemType Directory $batchPath\$_ > $null
        New-Item -ItemType Directory "$batchPath\$_\NoCreds" > $null
    }
    
    Write-Host "Done"

    # Create batch files
    $connections | ForEach-Object {
        Write-Host "Batch files for $($_.NAME)... " -NoNewline

        # Normal
        New-Item -Path "$batchPath\$($_.SITE)" -Name "$($_.NAME).bat" -ItemType File -Value `
            "@powershell.exe /c `"$binPath\puttyLauncher.ps1 -uid $($_.UID)`"" > $null
        
        # NoCreds
        New-Item -Path "$batchPath\$($_.SITE)\NoCreds" -Name "$($_.NAME).bat" -ItemType File -Value `
            "@powershell.exe /c `"$binPath\puttyLauncher.ps1 -uid $($_.UID) -nocreds`"" > $null
        
		# Assigned
        if ($_.FLAG -eq 1) {
            New-Item -Path "$batchPath\Assigned" -Name "$($_.NAME).bat" -ItemType File -Value `
                "@powershell.exe /c `"$binPath\puttyLauncher.ps1 -uid $($_.UID)`"" > $null

            New-Item -Path "$batchPath\Assigned\NoCreds" -Name "$($_.NAME).bat" -ItemType File -Value `
                "@powershell.exe /c `"$binPath\puttyLauncher.ps1 -uid $($_.UID) -nocreds`"" > $null
        }		

        Write-Host "Done"
    }

} elseif ($uid -ne "") {
    
    $connections | Where-Object { $_.UID -eq $uid } | ForEach-Object {
        
        if ($nocreds -eq $false) {
        
            # Launch putty with private key file, password, or no password
            if ($_.USER -ne "" -and $_.PASS -match "^.*?.ppk$") {
            
                # PPK file
                & $putty $_.IPADDR -l $_.USER -i "$binPath\$($_.PASS)"

            } elseif ($_.USER -ne "" -and $_.PASS -ne "") {
            
                # Password
                & $putty $_.IPADDR -l $_.USER -pw $_.PASS

            } elseif ($_.USER -ne "") {
            
                # No Password
                & $putty $_.IPADDR -l $_.USER

            } else {

                # No User
                & $putty $_.IPADDR
            }

        } else {

            # No credentials requested
            & $putty $_.IPADDR
        
        }
    }

} else {
   
    # Invalid command line operation
    Write-Output "Invalid operation, please only run the batch files.`n`nPress any key to continue..."
    Read-Host | Out-Null
    exit

}