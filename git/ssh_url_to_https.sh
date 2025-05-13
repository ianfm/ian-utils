#!/bin/bash
# convert an ssh url for git repo to https
# e.g. git@github.com:ianfm/repo.git
# to   https://github.com/ianfm/repo.git

# Check if an argument was provided
if [ -z "$1" ]; then
  echo "Usage: $0 <git-ssh-url>"
  exit 1
fi

# Input SSH URL
ssh_url="$1"

# Use parameter expansion and sed to convert to HTTPS
https_url=$(echo "$ssh_url" | sed -E 's#git@([^:]+):#https://\1/#')

echo "$https_url"
