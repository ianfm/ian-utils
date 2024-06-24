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
ssh-copy-id -o PreferredAuthentications=password -i "$KeyDir/$KeyName.pub" ubuntu@$RemoteHost

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
$dockerResult="docker context create $RemoteHost --docker \"host=ssh://$RemoteHost\""
# docker context create orin132 --docker "host=ssh://orin132"

if ($RemoteHost == $dockerResult) {
    echo "Host $RemoteHost can now be accessed via ssh/docker"
} else {
    echo "Docker command returned an unexpected value: "
    echo "$dockerResult"
    echo "Context not created."
    exit 0 
}



    
    
    
    
    
    
#     for ($i = 0; $i -lt $contexts.Count; $i++) {
#         if ($contexts[$i].contains($RemoteHost)) {
#             Write-Host "Found existing Docker context $RemoteHost. Removing context..."
#             $RmExpression = "docker context rm $RemoteHost"
#             Invoke-Expression $RmExpression
#             break
#         }
#     }
# } else {
#     Write-Host "Not creating a Docker context."
#     return
# }




