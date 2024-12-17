# SCRIPT:   new_remote_host.ps1
# PURPOSE:  Create new SSH key/config for a remote host from a Windows 11 machine. 
#           Optionally create a Docker context for the remote host.
# AUTHOR:   Ian McMurray


# TODOs:
#       -   Check for existing entries in .ssh/knownhosts that would raise an unrecognized hash error
#       -   Check for previous entries in remote-host's .ssh/authorized_keys file to avoid polluting it 
#            and maintain access control
#       -   Check for Docker context in-use before removing and creating new context (fails)

# Prerequisites: See https://farmx1.atlassian.net/wiki/spaces/GV/pages/2691465446/Docker+SSH+Context+on+Windows
# Assumes first-time local machine ssh setup is complete
# i.e. sshd service enabled and set to run on startup
#      likewise for ssh-agent
#### Set-PSDebug -Trace 1

# Required defaults
$KeyType='ed25519'
$KeyDir="$env:USERPROFILE\.ssh"
$KeyName="id_$RemoteHost"

# Query user for the name or IP of the remote host to establish connection to
$userInputRemoteHost = Read-Host "Provide the hostname or IP address of the remote host"
if ($userInputRemoteHost -eq "") {
    Write-Host "No host was selected. Aborting"
    return
} else {
    $RemoteHost = $userInputRemoteHost
    $KeyName="id_$RemoteHost"
}

# Query user for the username to log in with on the remote host
$userInputRemoteUser = Read-Host "Provide the username for host $userInputRemoteHost"
if ($userInputRemoteUser -eq "") {
    Write-Host "No user was selected. Aborting"
    return
} else {
    $RemoteUser = $userInputRemoteUser
}

# Create the new key
# enter enter for no password
ssh-keygen -t $KeyType -f $KeyDir/$KeyName

# Generate the SSH Command to send the pubkey to the remote host
$PUBKEY = Get-Content $KeyDir\$KeyName.pub
$CMDSTRING = "echo $PUBKEY >> /home/$RemoteUser/.ssh/authorized_keys"
$SSHFLAGS='-o PreferredAuthentications=password -o ConnectTimeout=10'
$fullCommand = "ssh $SSHFLAGS $RemoteUser@$RemoteHost '$CMDSTRING'"
Write-Host "Sending pubkey to remote host:"
Write-Host "$fullCommand"
$sshResult = Invoke-Expression "$fullCommand"

# # Check that the initial SSH connection does not time out
# if ($null -eq $sshResult) {
#     Write-Host "Pubkey sent"
# } elseif ($sshResult -like 'timed out') {
#     Write-Host "Failed to connect to remote"
#     return "Failed to connect to remote"
# } else {
#     Write-Host "ssh command returned an unexpected value"
#     return 
# }

# Hacky check that the initial SSH connection does not time out
$userInputSshFailCheck = Read-Host "Did the ssh command time out? (y/n)"
if ($userInputSshFailCheck -eq "y") {
    Write-Host "Failed to send pubkey. Aborting"
    Write-Host "The captured ssh output was $sshResult"
    return
}

# Finally, add the new key to ssh-agent to persist it
Start-Service ssh-agent
Get-Service ssh-agent
ssh-add $KeyDir/$KeyName

# TODO:check for existing entry with same Host name
Write-Host "Adding remote host entry to ssh config file. Note that you will have to remove any existing entries for the same host!"

# Append new host entry to .ssh/config
# TODO: remove existing entry if found 
#  OR   replace existing entry's key value with new keyname
Out-File -FilePath "$KeyDir/config" -InputObject "

Host $RemoteHost
    User $RemoteUser
    IdentityFile $KeyDir/$KeyName
    PreferredAuthentications publickey
    IdentitiesOnly yes
    ForwardX11 yes
" -Append -Encoding utf8 -NoClobber

# Ask if user wants a docker context too
$userInputNewContext = Read-Host "Do you want to create an associated docker context? (y/n)"
if ($userInputNewContext -eq "y") {
    Write-Host "Creating new Docker context $RemoteHost"
    # Try:
    $contexts = Invoke-Expression "docker context list"
    for ($i = 0; $i -lt $contexts.Count; $i++) {
        if ($contexts[$i].contains($RemoteHost)) {
            Write-Host "Found existing Docker context $RemoteHost. Removing context..."
            $RmExpression = "docker context rm $RemoteHost"
            Invoke-Expression $RmExpression
            break
        }
    }
} else {
    Write-Host "Not creating a Docker context."
    return
}

# Create Docker context using the new SSH key
$dockerResult = docker context create $RemoteHost --docker "host=ssh://$RemoteHost"

if ($RemoteHost -eq $dockerResult) {
    return "Success"
} else {
    Write-Host "Docker command returned an unexpected value. Context not created."
    return 
}
