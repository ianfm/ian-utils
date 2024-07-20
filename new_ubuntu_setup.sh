# Install system packages
sudo apt update -y
sudo apt upgrade -y
sudo apt install -y git gedit nmap net-tools build-essential can-utils curl wget make btop tmux x11-apps gparted
sudo apt install -y python3-pip python3-venv
sudo apt install -y linux-tools-$(uname -r) valgrind kcachegrind
sudo apt install -y code

# TODO:
# docker
# chrome

# Install python packages
python3 -m pip install matplotlib colorama asyncio websockets psutil requests pyshark pytest jupyter jupyterlab

# Update environment
export PATH=$PATH:/home/ian/.local/bin
echo "export PATH=$PATH:/home/ian/.local/bin" >> ~/.bashrc

# Git setup
git config --global user.name "Ian"
git config --global user.email "ianf.mcmurray@gmail.com"
git config --global credential.helper store

# Install utils
mkdir ~/src
cd ~/src
git clone https://github.com/ianfm/ian-utils.git
# use token from lastpass


