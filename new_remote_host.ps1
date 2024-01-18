# Assumes first-time ssh setup is complete
Set-PSDebug -Trace 1

# These default values are required
$KeyType='ed25519'
$KeyDir="$env:USERPROFILE\.ssh"

# These default values are not necessary
$RemoteHost='trashbot'
$RemoteUser='ian'
$KeyName="id_$RemoteHost"
$KeyPath="$KeyDir\$KeyName"

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
ssh-keygen -t $KeyType -f $KeyPath

# TODO: handle key already exists

# Generate the SSH Command to send the pubkey to the remote host
$PUBKEY = Get-Content $KeyPath.pub
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
ssh-add $KeyPath

# TODO: add ssh config entry like the following
Write-Host "Adding remote host entry to ssh config file:"
Out-File -FilePath "$KeyDir/config" -InputObject "Host $RemoteHost
    User $RemoteUser
    IdentityFile $KeyPath
    PreferredAuthentications publickey
    IdentitiesOnly yes
    ForwardX11 yes

" -Append -Encoding utf8 -NoClobber

# Ask if user wants a docker context too
$userInputNewContext = Read-Host "Do you want to create an associated docker context? (y/n)"
if ($userInputNewContext -eq "y") {
    Write-Host "Creating new Docker context $RemoteHost"
} else {
    Write-Host "Not creating a Docker context."
    return
}

# Create Docker context using the new SSH key
$dockerResult = docker context create $RemoteHost --docker "host=ssh://$RemoteHost"

if ($RemoteHost -eq $dockerResult) {
    return "Success"
} else {
    Write-Host "Docker command returned an unexpected value"
    return 
}
