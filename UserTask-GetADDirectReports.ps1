function Get-ADDirectReports {
	<#
	.SYNOPSIS
		This function retrieves user information for the specified user, then gathers the same information for
		all direct reports for that user. Optionally, the recursive flag can be set to continue to gather direct
		reports for each user until there are no further direct reports to pull from.
		Specifics of this operation and the information gathered are listed in DESCRIPTION below.
	
	.DESCRIPTION
		Script gathers the following details about the user from Active Directory:
			- Name [string]
			- enabled [boolean] : whether the account is enabled/disabled in Active Directory
			- SamAccountName [string] : the unique account name for the user (AD login name)
			- Mail [string] : email address associated with the account
			- Title [string] : job title associated with account
			- Manager [string] : SamAccountName of the direct supervisor (as designated by AD)
			- O365-Member [string] : Does a recursive search of account group membership and searches for a designated string - "Office365" -
				and lists all groups that match the search
		Output will be piped to a CSV file on the Desktop for %userprofile%\Desktop
	
	.NOTES
		Modified by Robert Fitting, Assoc. IT Technician
		Last Updated: 2017-06-27
		Original script from author below:
			Francois-Xavier Cat
			www.lazywinadmin.com
			@lazywinadm
	
	.PARAMETER Identity
		Specify the account to inspect
	
	.PARAMETER Recurse
		Specify that you want to retrieve all the indirect users under the specified account
	
	#>
	[CmdletBinding()]
	PARAM (
		[Parameter(Mandatory)]
		[String[]]$Identity,
		[Switch]$Recurse
	)
	BEGIN
	{
		TRY
		{
			IF (-not (Get-Module -Name ActiveDirectory)) { Import-Module -Name ActiveDirectory -ErrorAction 'Stop' -Verbose:$false }
		}
		CATCH
		{
			Write-Verbose -Message "[BEGIN] Something wrong happened"
			Write-Verbose -Message $Error[0].Exception.Message
		}
	}
	PROCESS
	{
		foreach ($Account in $Identity)
		{
			TRY
			{
				IF ($PSBoundParameters['Recurse'])
				{
					# Get the DirectReports
					Write-Verbose -Message "[PROCESS] Account: $Account (Recursive)"
					Get-Aduser -identity $Account -Properties directreports |
					ForEach-Object -Process {
						$_.directreports | ForEach-Object -Process {
							# Output the current object with the properties Name, SamAccountName, Mail and Manager
							Get-ADUser -Identity $PSItem -Properties enabled, mail, title, manager | Select-Object -Property Name, enabled, SamAccountName, Mail, Title, @{ Name = "Manager"; Expression = { (Get-Aduser -identity $psitem.manager).samaccountname } }, @{ Name = "O365-Member"; Expression = { (Get-AdUser -identity $psitem -Properties memberOf).memberOf | % {If ($_ -like "*Office365*" -and $_ -match "CN=([^,]+)") {$matches[1]} } } }
							# Gather DirectReports under the current object and so on...
							Get-ADDirectReports -Identity $PSItem -Recurse	
						}
					}
				}#IF($PSBoundParameters['Recurse'])
				IF (-not ($PSBoundParameters['Recurse']))
				{
					Write-Verbose -Message "[PROCESS] Account: $Account"
					# Get the DirectReports
					Get-Aduser -identity $Account -Properties directreports | Select-Object -ExpandProperty directReports |
					Get-ADUser -Properties enabled, mail, title, manager | Select-Object -Property Name, enabled, SamAccountName, Mail, Title, @{ Name = "Manager"; Expression = { (Get-Aduser -identity $psitem.manager).samaccountname } }, @{ Name = "O365-Member"; Expression = { (Get-AdUser -identity $psitem -Properties memberOf).memberOf | % {If ($_ -like "*Office365*" -and $_ -match "CN=([^,]+)") {$matches[1]} } } }
				}#IF (-not($PSBoundParameters['Recurse']))
			}#TRY
			CATCH
			{
				Write-Verbose -Message "[PROCESS] Something wrong happened"
				Write-Verbose -Message $Error[0].Exception.Message
			}
		}
	}
	END
	{
		Remove-Module -Name ActiveDirectory -ErrorAction 'SilentlyContinue' -Verbose:$false | Out-Null
	}
}# end ADDirectReports function

# BEGIN User Interface Code
function input {
	cls
	"AD account name required for search to function."
	""
	$aduser = Read-Host "AD Account / SamAccountName"
	""
	"Recursion will retrieve every direct report under the selected user."
	"It will then retrieve every report under those selected users, and so on.."
	""
	$recurse = Read-Host "Recursive? Y or N"
	cls
	"Is this information correct?"
	""
	"User: $aduser"
	"Recursive: $recurse"
	""
	$answer = Read-Host "Y or N"
	""
	
	if ($answer -like 'y') {
		if ($recurse -like 'y') {
			"Processing..."
			Get-ADDirectReports -Identity $aduser -Recurse | Export-Csv "$([Environment]::GetFolderPath("Desktop"))\$aduser.csv" -NoTypeInformation
		} elseif ($recurse -like 'n') {
			"Processing..."
			Get-ADDirectReports -Identity $aduser | Export-Csv "$([Environment]::GetFolderPath("Desktop"))\$aduser.csv" -NoTypeInformation
		}
	} else {
		input
	}
}

Do{
	cls
	input
	""
	"File has been created and saved to the desktop - $([Environment]::GetFolderPath("Desktop"))\"
	# Check if running Powershell ISE
	if ($psISE)
	{
	   Add-Type -AssemblyName System.Windows.Forms
	   [System.Windows.Forms.MessageBox]::Show("Press that there button to continue...")
	}
	else
	{
	   Write-Host "Press any key to continue..." -ForegroundColor Yellow
	   $x = $host.ui.RawUI.ReadKey("NoEcho,IncludeKeyDown")
	}
}
until
($ready -ne 'y')