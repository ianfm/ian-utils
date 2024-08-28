KeyType='ed25519'
KeyDir="$HOME/.ssh"
RemoteHost=""
KeyName="id_$RemoteHost"
UserEmail="ianf.mcmurray@gmail.com"
RemoteUser=""

echo "Provide the hostname or IP address of the remote host: "
read userInputRemoteHost
read -p "username: " RemoteUser
    
ssh-keygen -t ed25519 -C $UserEmail -f "$KeyDir/$KeyName" -N ""
eval "$(ssh-agent -s)"
ssh-add "$KeyDir/$KeyName"


