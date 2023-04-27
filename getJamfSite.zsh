#!/bin/zsh

# getJamfSite.zsh
# See README.md for usage

# Jamf scripts sends us the following:
# $1 = mount point
# $2 = computer name
# $3 = username

jssURL="$4"
credentials="$5"
plistFile="/Library/Application\ Support/JAMF/getJamfSite.plist"

## Error Messages
error_jssURL="The JSS URL (parameter 4) is not defined!"
error_credentials="The base-64 encoded JSS credentials (parameter 5) are not defined!"
error_plistFile="The target PLIST file from the script is not defined!"


function sanityCheck {
	# Without these variables, the script won't do anything
	# Parameters:
	# 1 - jssURL
	# 2 - credentials
	# 3 - plistFile
	
	if [ -z "$1" ]; then
		echo $error_jssURL
	elif [ -z "$2" ]; then
		echo $error_credentials
	fi
}

function main {
	echo "getJamfSite.zsh started."
	echo $plistFile
	errorMessage=$(sanityCheck $jssURL $credentials)
	if [ -n "$errorMessage" ]; then
		echo "Error!" $errorMessage
		echo "Aborting script with error"
		exit 1
	fi
	echo "Completed successfully."

}

function testing {
	echo "getJamfSite.zsh tests running."
	errorMessage=$(sanityCheck $jssURL $credentials)
	if [ -n "$errorMessage" ]; then
		echo "Error!" $errorMessage
		echo "Aborting script with error"
		exit 1
	fi
	
	echo "sanityCheck on empty jssURL"
	errorMessage=$(sanityCheck "" $credentials)
	if [ "$errorMessage" = "$error_jssURL" ]; then
		echo "\t...success"
	else
		echo "...FAIL"
		exit 1
	fi
	
	echo "sanityCheck on empty credentials"
	errorMessage=$(sanityCheck $jssURL "")
	if [ "$errorMessage" = "$error_credentials" ]; then
		echo "\t...success"
	else
		echo "\t...FAIL"
		exit 1
	fi
		
	
	echo "Completed successfully."

}

if [ "$6" = "test" ]; then
	testing
else
	main
fi
