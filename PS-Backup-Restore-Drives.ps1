<#	
	.NOTES
	===========================================================================
	 Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2019 v5.6.167
	 Created on:   	23-Aug-19 8:42 PM
	 Created by:   	Clement Campagna (https://github.com/clementcampagna)
	 Tested on:		Windows 10 Pro / PowerShell 5.1
	 Filename:     	PS-Backup-Restore-Drives.ps1
	 License:		MIT License

		Copyright (c) 2019 Clement Campagna

		Permission is hereby granted, free of charge, to any person obtaining a copy
		of this software and associated documentation files (the "Software"), to deal
		in the Software without restriction, including without limitation the rights
		to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
		copies of the Software, and to permit persons to whom the Software is
		furnished to do so, subject to the following conditions:

		The above copyright notice and this permission notice shall be included in all
		copies or substantial portions of the Software.

		THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
		IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
		FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
		AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
		LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
		OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
		SOFTWARE.
	
	===========================================================================
	.DESCRIPTION
		This PowerShell script helps ensure that a target drive becomes or stays 
		identical to a source drive by copying, overwriting, and/or removing files 
		and folders on the target drive in order to match the structure and data of
		the source drive.
		
		Usage:
		PS > .\PS-Backup-Restore-Drives.ps1 (or right-click on the file > Run with PowerShell)
		or
		PS > .\PS-Backup-Restore-Drives.ps1 -sourceDrive E:\ -targetDrive F:\
		or
		PS > .\PS-Backup-Restore-Drives.ps1 -sourceDrive E:\ -targetDrive F:\ -bypassUserConfirmation
#>

param (
	[string]$sourceDrive,
	[string]$targetDrive,
	[switch]$bypassUserConfirmation
)

if (!$sourceDrive)
{
	$sourceDrive = Read-Host -Prompt 'Please input the source drive path (e.g. E:\)'
}

if (!$targetDrive)
{
	$targetDrive = Read-Host -Prompt 'Please input the target drive path (e.g. F:\)'
}

Write-Host "`nYou have choosen $sourceDrive as the source drive and $targetDrive as the target drive."

if (!$bypassUserConfirmation)
{
	Write-Host "`nWARNING:`nAnswering YES to the following question means that any file or folder that differs between the source and target drives will either be copied to/overwritten on or removed from the target drive to mirror the source drive!`n"
	$confirmation = Read-Host "Please confirm that you wish to make $targetDrive identical to $sourceDrive by typing YES (case-sensitive)"
}

if ($confirmation -eq 'YES' -or $bypassUserConfirmation)
{
	if ($confirmation -eq 'YES')
	{
		Write-Host "`nConfirmation received, carrying on script execution..."
	}
	else
	{
		Write-Host "`nConfirmation bypassed, carrying on script execution..."
	}
	
	Write-Host "`nEnumerating all files and folders on $sourceDrive, this might take a while..."
	$sourceDriveFiles = Get-ChildItem -Path $sourceDrive -Recurse -Force -ErrorAction Ignore
	
	Write-Host "Enumerating all files and folders on $targetDrive, this might take a while..."
	$targetDriveFiles = Get-ChildItem -Path $targetDrive -Recurse -Force -ErrorAction Ignore
	
	Write-Host "`nReady to start!"
	Write-Host "`nMaking $targetDrive identical to $sourceDrive, please hold on as this might take a while...`n"
	foreach ($file in $sourceDriveFiles)
	{
		$sourceFilePath = $file.FullName
		$destinationFilePath = $sourceFilePath.replace(($sourceFilePath.Substring(0, 3)), $targetDrive)
		$filePath = Split-Path -LiteralPath $destinationFilePath
		
		if (Test-Path -LiteralPath $destinationFilePath -ErrorAction Ignore)
		{
			if ((Get-Item -LiteralPath $destinationFilePath -ErrorAction Ignore) -isnot [System.IO.DirectoryInfo])
			{
				Write-Host "$sourceFilePath exists on $targetDrive, checking if files match"
				
				[string]$sourceFile = Get-ChildItem -LiteralPath $sourceFilePath -ErrorAction Ignore | select LastWriteTime, Length
				[string]$destFile = Get-ChildItem -LiteralPath $destinationFilePath -ErrorAction Ignore | select LastWriteTime, Length
				
				if ($sourceFile -ne $destFile)
				{
					Write-Host "$sourceFilePath differs from the copy stored on $targetDrive, overwriting it on $targetDrive now"
					New-Item -ItemType Directory -Path $filePath -ErrorAction Ignore
					Copy-Item -LiteralPath $sourceFilePath $destinationFilePath -ErrorAction Ignore
				}
			}
		}
		else
		{
			Write-Host "$sourceFilePath does not exist on $targetDrive, copying it now"
			New-Item -ItemType Directory -Path $filePath -ErrorAction Ignore
			Copy-Item -LiteralPath $sourceFilePath $destinationFilePath -Force -ErrorAction Ignore
		}
	}
	
	foreach ($file in $targetDriveFiles)
	{
		$destinationFilePath = $file.FullName
		$sourceFilePath = $destinationFilePath.replace(($destinationFilePath.Substring(0, 3)), $sourceDrive)
		
		Write-Host "Checking if $destinationFilePath still exists on $sourceDrive, please wait"
		
		if (!(Test-Path -LiteralPath $sourceFilePath -ErrorAction Ignore) -and (Test-Path -LiteralPath $destinationFilePath -ErrorAction Ignore))
		{
			Write-Host "$destinationFilePath does not exist on $sourceDrive, deleting it from $targetDrive now"
			Remove-Item -LiteralPath $destinationFilePath -Recurse -Force -ErrorAction Ignore
		}
	}
	
	Write-Host "`nJob complete!"
	
	if (!$bypassUserConfirmation)
	{
		pause
	}
}
else
{
	Write-Host "`nConfirmation failed. Exiting now...`n"
	pause
}