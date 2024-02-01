#!/bin/bash
#container_setup.sh
git config --global user.name "Ian McMurray"
git config --global user.email "ianf.mcmurray@gmail.com"
git config --global alias.tree "log --all --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit" 

# Modify config files
echo '# git shortcuts    
alias gs="git status"
alias gf="git fetch"
alias gss="git status -sb"
alias gb="git branch -a"
alias gl="git log --format=reference --relative-date" ' \
 >> /home/ubuntu/.bash_aliases

# Add colcon autocomplete
sudo apt-get install python3-colcon-argcomplete
source /usr/share/colcon_argcomplete/hook/colcon-argcomplete.bash 
echo 'source /usr/share/colcon_argcomplete/hook/colcon-argcomplete.bash' \
 >> /home/ubuntu/.bashrc

# Fix nano quirks
echo 'set tabsize 4
extendsyntax python tabgives "    "
extendsyntax makefile tabgives "	"
' \
 >> ~/.nanorc

# IF ssh key has not already been mounted, i.e. on local dev machine
# Tested on alienware docker, works!
if [ -f ~/.ssh/id_github ]; then
    echo "key exists, skipping keygen"
else
    ssh-keygen -t rsa -b 4096 -C "ianf.mcmurray@gmail.com" -f "/home/ubuntu/.ssh/id_github" -N ""
    # eval "$(ssh-agent -s)"
    # ssh-add /home/ubuntu/.ssh/id_github
fi


# Copy key to github
# cat ~/.ssh/id_github.pub

type -p curl >/dev/null || (sudo alspt update && sudo apt install curl -y)
curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg \
&& sudo chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg \
&& echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
&& sudo apt update \
&& sudo apt-get -qqy install gh

# Set up github auth
read -p "input your GitHub token" token
echo ${token} | gh auth login --with-token
gh config set git_protocol ssh --host github.com
gh auth status

# Add new ssh key
eval "$(ssh-agent -s)"
ssh-add /home/ubuntu/.ssh/id_github

gh ssh-key add "/home/ubuntu/.ssh/id_github.pub" --title $CONTAINER_ID 
#--type authentication        # not recognized anymore

# Clone test repo
cd ~/ros2_ws/src; git clone git@github.com:AutoModality/am_super.git -q

# Apply required VS Code settings for intellisense
mkdir -p /home/ubuntu/ros2_ws/.vscode
echo \
'"ros.rosSetupScript": "/home/ubuntu/ros2_ws/install/setup.bash",
"C_Cpp.default.cppStandard": "c++17",
"C_Cpp.default.cStandard": "c99",
"[cpp]": {
    "editor.defaultFormatter": "ms-iot.vscode-ros"
},
"ros2.additionalSearchDirs": [
    "/home/ubuntu/ros2_ws/install",
    "/home/ubuntu/ros2_amros/install",
    "/opt/ros2_ws/install",
    "/opt/ros/humble/install",
],
' > /home/ubuntu/ros2_ws/.vscode/settings.json
