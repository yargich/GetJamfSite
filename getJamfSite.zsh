#!/bin/zsh

# getJamfSite.zsh
# See README.md for usage

# Jamf scripts sends us the following:
# $1 = mount point
# $2 = computer name
# $3 = username

jssURL="$4"
credentials="$5"
debug=false
plistFile="/Library/Application Support/JAMF/getJamfSite.plist"
udid=""
token=""
site=""

## Error Messages
error_jssURL="The JSS URL (parameter 4) is not defined!"
error_credentials="The base-64 encoded JSS credentials (parameter 5) are not defined!"
error_plistFile="The target PLIST file from the script is not defined!"

function debug {
	if $debug; then echo "$@"; fi
}

function sanityCheck {
	# Without these variables, the script won't do anything
	# Parameters:
	# 1 - jssURL
	# 2 - credentials	
	if [ -z "$1" ]; then
		echo $error_jssURL
	elif [ -z "$2" ]; then
		echo $error_credentials
	fi
}

function getUDID {
	# Get the UDID number from the local computer
	udid=$(ioreg -d2 -c IOPlatformExpertDevice | awk -F\" '/IOPlatformUUID/{print $(NF-1)}')
	if [ -z $udid ]; then
		echo "Error! Unable to get Mac UDID!"
		return 1
	fi
}

function getToken {
	# Connects to the Jamf server and requests an auth token
	authToken=""
	# request an authorization token
	authToken=$( /usr/bin/curl \
		--request POST \
		--silent \
		--url "$jssURL/api/v1/auth/token" \
		--header "authorization: Basic $credentials"
	)
	if [ -z "$authToken" ]; then
		echo "Unable to fetch auth token from server -- check your credentials and server name"
		exit 1
	fi
	debug $authToken
	if ! token=$( /usr/bin/plutil \
		-extract "token" raw - <<< "$authToken"
	); then
		echo "Unable to extract token -- server error"
		exit 1
	fi
	debug $token
}

function getComputer {
	# Connects to the Jamf server and requests the computer record
	url="$jssURL/JSSResource/computers/udid/$udid"
	debug $url

	if ! computerRaw=$( /usr/bin/curl \
	--header "Accept: application/json" \
	--request GET \
	--silent \
	--url "$url" \
	--header "Authorization: Bearer $token" \
	--write-out "%{http_code}"
	); then 
		echo "No results from server"
		exit 1
	fi
	# computer record without the status code
	computerJson=${computerRaw:0:-3}
	# status code
	statusCode=${computerRaw: -3}
	
	if [ -z "$computerJson" ]; then
		echo "No response from server"
		exit 1
	fi
	debug "Raw JSON: ${computerJson:0:150}..."
	debug  "Status Code: $statusCode"
	if [ "${statusCode:0:1}" != "2" ]; then
		echo "Server returned invalid status code ($statusCode)"
		exit 1
	fi
	if ! site=$( /usr/bin/plutil \
	-extract "computer"."general"."site"."name" raw - <<< "$computerJson"
	); then
		echo "Could not parse site name from server response"
		exit 1
	fi
	debug "Computer Site: $site"
}

function writePlist {
	# writes site and current date to local PLIST file
	if ! /usr/bin/defaults write "$plistFile" site "$site"; then
		echo "Error writing site to defaults file!"
		exit 1
	fi
	if ! /usr/bin/defaults write "$plistFile" updated "`date`"; then
		echo "Error writing date to defaults file!"
		exit 1
	fi
	debug "Site from PLIST" $(/usr/bin/defaults read "$plistFile" site)
	debug "Date from PLIST" $(/usr/bin/defaults read "$plistFile" updated)
}

function main {
	echo "getJamfSite.zsh started."
	errorMessage=$(sanityCheck $jssURL $credentials $udid)
	if [ -n "$errorMessage" ]; then
		echo "Error!" $errorMessage
		echo "Aborting script with error"
		exit 1
	fi
	getUDID
	getToken
	getComputer
	writePlist
	echo "Completed successfully."

}

function testing {
	# Verbose testing run
	echo "getJamfSite.zsh tests running."
	errorMessage=$(sanityCheck $jssURL $credentials $udid)
	if [ -n "$errorMessage" ]; then
		echo "Error!" $errorMessage
		echo "Aborting script with error"
		exit 1
	fi
	
	echo "sanityCheck on empty jssURL"
	errorMessage=$(sanityCheck "" $credentials $udid)
	if [ "$errorMessage" = "$error_jssURL" ]; then
		echo "\t...success"
	else
		echo "...FAIL"
		exit 1
	fi
	
	echo "sanityCheck on empty credentials"
	errorMessage=$(sanityCheck $jssURL "" $udid)
	if [ "$errorMessage" = "$error_credentials" ]; then
		echo "\t...success"
	else
		echo "\t...FAIL"
		exit 1
	fi
	
	echo "Getting UDID from local computer"
	getUDID
	echo "UDID:" $udid
	
	echo "Getting token from server"
	getToken
	
	echo "Getting computer data from server"
	getComputer
	
	echo "Writing PLIST file"
	writePlist
	
	echo ""
	echo "Completed successfully."

}

if [ "$6" = "test" ]; then 
	debug=true
	testing
else 
	main
fi
