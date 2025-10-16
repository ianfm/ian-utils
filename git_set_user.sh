#!/bin/bash
# To run once on container startup
# Prompt the user for their Git credentials

echo "Please enter your Git credentials."

read -p "github username: " username
read -p "github email: " email
echo -n "github personal access token: "
read -s token
echo

# set user details in gitconfig for commit authorship
cat > "/home/$USER/.gitconfig" <<EOF
[user]
    name = ${username}
    email = ${email}
[credential]
    helper = store
EOF

# write the token to a credential store
mkdir -p /home/$USER/.config/git
cat <<EOF > /home/$USER/.config/git/credentials
https://$username:$token@github.com
EOF

chmod 600 /home/$USER/.config/git/credentials
echo "Git config and token stored successfully."
