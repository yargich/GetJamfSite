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

## Usage
This repo has two scripts: 
- `getJamfSite.zsh` should be run as a script in a policy at some kind of regular
interval (daily, weekly, or whatever need your organization has) and takes the following
parameters:
	- $4 is your Jamf server's URL (without the trailing slash)
	- $5 is the base-64 encoded credentials to an account with read access to whatever
	computer objects you want to search (in most cases, the full Jamf server)
	- $6 is set up for script testing -- put `test` in this variable to check 
	functionality
- `getExtAttribute.zsh` should be run as an extension attribute. It retrieves the site
stored in a PLIST by the previous script (if any) and makes it a Jamf attribute.

At the moment, I'm just doing this for our group, but it would be lovely if other groups
find some kind of use in it.

## Encoding Credentials
To obtain base-64 encoded credentials for an account, you can either find a web site
to help you do so, or else use a shell command like:
`printf "username:password" | iconv -t ISO-8859-1 | base64 -i -` (changing username and
password to your actual credentials). You can find more details 
[here](https://developer.jamf.com/jamf-pro/docs/code-samples).

## Thanks
The script part borrows heavily from a script by dennisnardi on the Jamf Community site
that you can find
[here](https://community.jamf.com/t5/jamf-pro/custom-extension-attribute-based-on-site/m-p/228424).

It also uses a lot of the techniques from 
[How to convert Classic API scripts to use bearer token authentication](https://community.jamf.com/t5/tech-thoughts/how-to-convert-classic-api-scripts-to-use-bearer-token/ba-p/273910)
on the Jamf Community site. 