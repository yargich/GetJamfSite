#!/bin/zsh

# getJamfSite.zsh
# See README.md for usage


function main {
	echo "getJamfSite.zsh started."

}

function testing {
	echo "getJamfSite.zsh tests running."
}

if [ "$6" = "test" ]; then
	testing
else
	main
fi

