# Set up new SSH target and associated docker context

# Locals
KeyType='ed25519'
KeyDir="$HOME/.ssh"
KeyName="id_$RemoteHost"
UserEmail="ianf.mcmurray@gmail.com"
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
    ssh-keygen -t ed25519 -C $UserEmail -f "$KeyDir/$KeyName" -N ""
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
    else
        echo "Not creating a Docker context."
        exit 0
    fi
fi


# Create Docker context using the new SSH key
dockerResult=$(docker context create $RemoteHost --docker "host=ssh://$RemoteHost")

if [[ $RemoteHost == $dockerResult ]]; then
    echo "Success"
else
    echo "Docker command returned an unexpected value. Context not created."
    exit 1
fi


## Sample output
# -----------------------------------------------------------------------------
# Provide the hostname or IP address of the remote host: 
# orin111
# username: ubuntu
# userInputRemoteHost = orin111
# KeyName = id_orin111
# key exists, skipping keygen
# /usr/bin/ssh-copy-id: INFO: Source of key(s) to be installed: "/home/ianx/.ssh/id_orin111.pub"
# /usr/bin/ssh-copy-id: INFO: attempting to log in with the new key(s), to filter out any that are already installed

# /usr/bin/ssh-copy-id: WARNING: All keys were skipped because they already exist on the remote system.
#                 (if you think this is a mistake, you may want to use -f option)

# Do you want to create an associated docker context? (y/n): 
# y
# Creating new Docker context orin111
# Found existing Docker context orin111. Removing context...
# default
# Current context is now "default"
# orin111
# Successfully created context "orin111"
# Success


