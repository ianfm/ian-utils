# Make sure you're running as an Administrator.
Get-Service ssh-agent | Set-Service -StartupType Automatic

# Back to user-permission shell
ssh-keygen -t ed25519 -f $env:USERPROFILE\.ssh\id_phat-al_enma
# enter enter
Start-Service ssh-agent
Get-Service ssh-agent
ssh-add $env:USERPROFILE\.ssh\id_phat-al_enma
ssh ian@phat-al "echo 'ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJhgQAQdQqt3zii0EubwXPkqWeURnxapoRSQO8AQi2K5 ianfm@Enma' >> ~/.ssh/authorized_keys"
