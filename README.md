# UserTask-GetADDirectReports

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
