#!/bin/zsh

# getJamfSite.zsh
# See README.md for usage

# Jamf scripts sends us the following:
# $1 = mount point
# $2 = computer name
# $3 = username

jssURL="$4"
credentials="$5"
plistFile="/Library/Application Support/JAMF/getJamfSite.plist"
uuID=""
token=""
site=""

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

function getUUID {
	uuID=$(ioreg -d2 -c IOPlatformExpertDevice | awk -F\" '/IOPlatformUUID/{print $(NF-1)}')
	if [ -z $uuID ]; then
		echo "Error! Unable to get Mac UUID!"
		return 1
	fi
}

function getToken {
	# $1 - if 'test' then display testing info
	
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
	if [ "$1" = "test" ]; then echo "$authToken"; fi
	token=$( /usr/bin/plutil \
	-extract token raw - <<< "$authToken"
	)
	if [ -z "$token" ]; then
		echo "Unable to extract token -- server error"
		exit 1
	fi
	if [ "$1" = "test" ]; then echo "$token"; fi

}

function getComputer {
	# $1 - if 'test' then display testing info
	
	url="$jssURL/JSSResource/computers/udid/$uuID"
	if [ "$1" = "test" ]; then echo "$url"; fi

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
	computerJson=${computerRaw::-3}
	statusCode=${computerRaw: -3}
	
	if [ -z "$computerJson" ]; then
		echo "No response from server"
		exit 1
	fi
	if [ "$1" = "test" ]; then 
		echo "Raw JSON: ${computerJson:0:150}..."
		echo "Status Code: $statusCode"
	fi
	if [ "${statusCode::1}" != "2" ]; then
		echo "Server returned invalid status code"
		exit 1
	fi
	if ! site=$( /usr/bin/plutil \
	-extract "computer"."general"."site"."name" raw - <<< "$computerJson"
	); then
		echo "Could not parse site name from server response"
		exit 1
	fi
	if [ "$1" = "test" ]; then echo "Computer Site: $site"; fi
}

function writePlist {
	# $1 - if 'test' then display testing info

	if ! /usr/bin/defaults write "$plistFile" site "$site"; then
		echo "Error writing site to defaults file!"
		exit 1
	fi
	if ! /usr/bin/defaults write "$plistFile" updated "`date`"; then
		echo "Error writing date to defaults file!"
		exit 1
	fi
	if [ "$1" = "test" ]; then 
		echo "Site from PLIST" $(/usr/bin/defaults read "$plistFile" site)
		echo "Date from PLIST" $(/usr/bin/defaults read "$plistFile" updated)
	fi
}

function main {
	echo "getJamfSite.zsh started."
	errorMessage=$(sanityCheck $jssURL $credentials $uuID)
	if [ -n "$errorMessage" ]; then
		echo "Error!" $errorMessage
		echo "Aborting script with error"
		exit 1
	fi
	getUUID
	getToken
	getComputer
	writePlist
	echo "Completed successfully."

}

function testing {
	echo "getJamfSite.zsh tests running."
	errorMessage=$(sanityCheck $jssURL $credentials $uuID)
	if [ -n "$errorMessage" ]; then
		echo "Error!" $errorMessage
		echo "Aborting script with error"
		exit 1
	fi
	
	echo "sanityCheck on empty jssURL"
	errorMessage=$(sanityCheck "" $credentials $uuID)
	if [ "$errorMessage" = "$error_jssURL" ]; then
		echo "\t...success"
	else
		echo "...FAIL"
		exit 1
	fi
	
	echo "sanityCheck on empty credentials"
	errorMessage=$(sanityCheck $jssURL "" $uuID)
	if [ "$errorMessage" = "$error_credentials" ]; then
		echo "\t...success"
	else
		echo "\t...FAIL"
		exit 1
	fi
	
	echo "Getting UUID from local computer"
	getUUID
	echo "UUID:" $uuID
	
	echo "Getting token from server"
	getToken "test"
	
	echo "Getting computer data from server"
	getComputer "test"
	
	echo "Writing PLIST file"
	writePlist "test"
	
	echo ""
	echo "Completed successfully."

}

if [ "$6" = "test" ]; then
	testing
else
	main
fi
