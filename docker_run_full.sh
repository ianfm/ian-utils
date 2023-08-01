docker run -it --net=host --privileged -v /dev/shm:/dev/shm -v /tmp/.X11-unix:/tmp/.X11-unix -e DISPLAY=$DISPLAY --runtime nvidia --name blursed_chow automodality/jetson-marti:latest


docker run -it --net=host --privileged --volume=/dev:/dev --volume=/var/run/dbus:/run/dbus:ro -v /dev/shm:/dev/shm -v /tmp/.X11-unix:/tmp/.X11-unix -e DISPLAY=$DISPLAY --runtime=nvidia --gpus all --name lewd_beowulf automodality/amd64-20.04-isaac-marti


automodality/amd64-20.04-isaac-marti


# isaac-marti JETSON


# isaac-marti AMD


read CONTAINER
docker run -it --net=host --privileged --volume=/dev:/dev --volume=/var/run/dbus:/run/dbus:ro -v /dev/shm:/dev/shm -v /tmp/.X11-unix:/tmp/.X11-unix -e DISPLAY=$DISPLAY --runtime=nvidia --gpus all --name $CONTAINER automodality/amd64-20.04-isaac-marti:latest



# SIM AMD
docker run -it --net=host --privileged --volume=/dev:/dev --volume=/var/run/dbus:/run/dbus:ro --volume=/var/logs/amros:/var/logs/amros -v /dev/shm:/dev/shm -v /tmp/.X11-unix:/tmp/.X11-unix -e AM_PLATFORM=km5_sim -e DISPLAY=$DISPLAY --runtime=nvidia --gpus all --name first_sim automodality/amd64-20.04-im-sim:latest
