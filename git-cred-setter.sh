#!/bin/bash
# To run once on container startup
# Prompt the user for their Git credentials
echo "Please enter your Git credentials."


read -p "github username: " username
read -p "github email: " email
echo "github password: " 
read -s token

# set user details in gitconfig for commit authorship
echo "
[user]
        email = $email
        name = $username
" > /home/$USER/.gitconfig

# Initialize an empty credential helper cache
git config --global credential.helper cache

# Use git credential to fill in the username and password
{
  echo "protocol=https"
  echo "host=github.com" 
  echo "username=$username"
  echo "password=$token"
} | git credential approve

echo "Git credentials have been saved."
