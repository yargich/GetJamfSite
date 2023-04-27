#!/bin/zsh

# See README.md for usage

plistFile="/Library/Application Support/JAMF/getJamfSite.plist"

if ! site=$(defaults read "$plistFile" site 2>/dev/null); then
	echo "<result>--NOT FOUND--</result>"
else
	echo "<result>$site</result>"
fi
