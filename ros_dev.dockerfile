# Dockerfile.ros2
FROM automodality/jetson-isaac2:latest

RUN /usr/bin/python3.8 -m pip install websockets

# Make ssh dir
RUN mkdir /home/ubuntu/.ssh/

# Copy over private key
ADD id_orin131_github /home/ubuntu/.ssh/id_orin131_github
# Elevate privileges temporarily
USER root
# Set keyfile permissions
RUN chmod 700 /home/ubuntu/.ssh/id_orin131_github \
    && touch /home/ubuntu/.ssh/known_hosts \
    && chown -R ubuntu:ubuntu /home/ubuntu/.ssh 

# Be user again
USER ubuntu

# Pull relevant code for development:
# Strategy:
    # 1. register github auth key and ssh config
    # 2. pull repos
    # 3. modify existing repos if needed
RUN ssh-keyscan github.com >> /home/ubuntu/.ssh/known_hosts \
    && echo "Host github.com\n    HostName github.com\n    IdentityFile ~/.ssh/id_orin131_github" >> /home/ubuntu/.ssh/config \
    && eval "$(ssh-agent -s)" \
    && ssh-add /home/ubuntu/.ssh/id_orin131_github \
    && source /home/ubuntu/.bashrc \
    && cd /home/ubuntu/ros2_ws/src \
    && git clone git@github.com:AutoModality/am_autosteer.git -b dev \
    && git clone git@github.com:ros-drivers/joystick_drivers.git -b ros2 \
    && rm -rf am_config \
    && git clone git@github.com:AutoModality/am_config -b GV-3544/jd-config \
    && cd amroscli2 \
    && git remote set-url origin git@github.com:AutoModality/amroscli2.git \
    && git fetch \
    && git checkout ros2 \
    && git pull

WORKDIR /home/ubuntu/ros2_ws

# Install easy dependency packages
RUN source /home/ubuntu/.bashrc && \
    source /home/ubuntu/ros2_ws/install/setup.bash && \
    colcon build --packages-ignore spacenav wiimote_msgs wiimote

# Install tricky dependency packages (separate stage)
RUN source /home/ubuntu/.bashrc \
    && source /home/ubuntu/ros2_ws/install/setup.bash \
    && colcon build --cmake-clean-cache --cmake-clean-first --packages-select am_config 

USER root

# allow colcon build to run without sudo
RUN chown -R ubuntu:ubuntu /home/ubuntu/ros2_ws

COPY ros_entrypoint.sh /ros_entrypoint.sh

ENTRYPOINT ["/ros_entrypoint.sh"]
CMD ["bash"]
