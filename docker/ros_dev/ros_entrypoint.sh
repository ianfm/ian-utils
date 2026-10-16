#!/bin/bash
set -e

# Source the ROS2 setup scripts
source /opt/ros/humble/setup.bash
source /usr/share/colcon_argcomplete/hook/colcon-argcomplete.bash

export ROS_LOCALHOST_ONLY=0
export ROS_DOMAIN_ID=3

# Execute the passed command or default to bash if none provided
exec "$@"
