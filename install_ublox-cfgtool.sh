mkdir ~/src
cd ~/src
git clone https://github.com/phkehl/ubloxcfg.git
cd ubloxcfg
make cfgtool
sudo cp output/cfgtool-release /usr/bin/
cfgtool-release status -p /dev/ttyRTK0