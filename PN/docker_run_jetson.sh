CONTAINER_NAME=super_testing
docker run -it --net=host --privileged --volume=/dev:/dev --volume=/var/run/dbus:/run/dbus:ro --volume=/var/logs/amros:/var/logs/amros -v /dev/shm:/dev/shm -v /tmp/.X11-unix:/tmp/.X11-unix -e AM_PLATFORM=amiga -e DISPLAY=$DISPLAY --runtime=nvidia --gpus all --name $CONTAINER_NAME automodality/jetson-isaac-marti:latest


# REGULAR JETSON
docker run -it --net=host --privileged --volume=/dev:/dev --volume=/var/run/dbus:/run/dbus:ro --volume=/var/logs/amros:/var/logs/amros -v /dev/shm:/dev/shm -v /tmp/.X11-unix:/tmp/.X11-unix -e AM_PLATFORM=amiga -e DISPLAY=$DISPLAY --runtime=nvidia --gpus all --name first_sim automodality/jetson-isaac-marti:latest

