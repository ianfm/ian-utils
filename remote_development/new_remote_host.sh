# Set up new SSH target and associated docker context

# Locals
KeyType='ed25519'
KeyDir="$HOME/.ssh"
KeyName="id_$RemoteHost"
RemoteUser="ubuntu"

# Query user for the name or IP of the remote host to establish connection to
echo "Provide the hostname or IP address of the remote host: "
read userInputRemoteHost
read -p "username: " RemoteUser

if [ -z $userInputRemoteHost ] ; then
    echo "No host was selected. Aborting"
    exit 1
else
    echo "userInputRemoteHost = $userInputRemoteHost"
    RemoteHost=$userInputRemoteHost
    KeyName="id_$RemoteHost"
    echo "KeyName = $KeyName"
fi

# DEBUG
# echo "RemoteHost = $RemoteHost"
# echo "userInputRemoteHost = $userInputRemoteHost"
# echo "KeyName = $KeyName"
# echo "KeyDir = $KeyDir"

# Create the new key
if [ -f "$KeyDir/$KeyName" ]; then
    echo "key exists, skipping keygen"
else
    ssh-keygen -t ed25519 -C $(uname -n) -f "$KeyDir/$KeyName" -N ""
    eval "$(ssh-agent -s)"
    ssh-add "$KeyDir/$KeyName"
fi


# Copy key to target host
ssh-copy-id -o PreferredAuthentications=password -i "$KeyDir/$KeyName.pub" $RemoteUser@$RemoteHost

#Create ssh config entry
echo "
Host $RemoteHost
    User $RemoteUser
    IdentityFile $KeyDir/$KeyName
    PreferredAuthentications publickey
    IdentitiesOnly yes
    ForwardX11 yes
" >> "$KeyDir/config"


# Ask if user wants a docker context too
echo "Do you want to create an associated docker context? (y/n): "
read userInputNewContext

if [ $userInputNewContext == "y" ]; then
    echo "Creating new Docker context $RemoteHost"
    
    contexts=$(docker context list)
    if [ -n "$contexts" ]; then
        for i in "${!contexts[@]}"; do
	        if [[ "${contexts[$i]}" == *"$RemoteHost"* ]]; then
	            echo "Found existing Docker context $RemoteHost. Removing context..."
                # switch to default context in case context to be removed is in use
	            docker context use default
	            docker context rm "$RemoteHost"
	            break
	        fi
        done
    fi

    # Create Docker context using the new SSH key
    dockerResult=$(docker context create $RemoteHost --docker "host=ssh://$RemoteHost")

    if [[ $RemoteHost == $dockerResult ]]; then
        echo "Success"
    else
        echo "Docker command returned an unexpected value. Context not created."
        exit 1
    fi
else
    echo "Not creating a Docker context."
    exit 0
fi




## Sample output
# -----------------------------------------------------------------------------
# ian@lenai:~/src/ian-utils$ ./remote_development/new_remote_host.sh 
# Provide the hostname or IP address of the remote host: 
# flashy
# username: good
# userInputRemoteHost = flashy
# KeyName = id_flashy
# key exists, skipping keygen
# /usr/bin/ssh-copy-id: INFO: Source of key(s) to be installed: "/home/ian/.ssh/id_flashy.pub"
# /usr/bin/ssh-copy-id: INFO: attempting to log in with the new key(s), to filter out any that are already installed
# /usr/bin/ssh-copy-id: INFO: 1 key(s) remain to be installed -- if you are prompted now it is to install the new keys
# good@flashy's password: 

# Number of key(s) added: 1

# Now try logging into the machine, with:   "ssh -o 'PreferredAuthentications=password' 'good@flashy'"
# and check to make sure that only the key(s) you wanted were added.

# Do you want to create an associated docker context? (y/n): 
# n
# Not creating a Docker context.

