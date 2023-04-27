# GetJamfSite
Script to get the Jamf site for the active computer and store it in a PLIST file

Current versions of Jamf do not allow reporting or criteria based on the Jamf site a
computer belongs to. The script here can be installed on a Jamf server and run as a
policy to retrieve the site and store it into a local PLIST file entry. Later, an 
extension attribute script can be added to retrieve that entry to store it in Jamf.

I don't currently recommend putting the main script directly into an extension attribute 
because: 
1. The script makes a Jamf API call, which is network dependent, and it would slow down
inventory collection.
2. In my organization, computers rarely (if ever) move site to site, so there is no need
to retrieve their site as frequently as Jamf's regular check-in period.