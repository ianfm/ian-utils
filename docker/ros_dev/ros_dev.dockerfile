# Dockerfile.ros2
FROM arm64v8/ros:humble

SHELL ["/bin/bash", "-c"]

ARG KEYFILE="id_github"
ARG USERNAME=root
ARG HOMEDIR="."
ARG ROSDIR="/opt/ros2_ws"

# Make ssh dir
RUN mkdir ${HOMEDIR}/.ssh/

RUN apt-get update && apt-get install -y git openssh-client

# Copy private key for github, set permissions as root, drop back into user land
ADD ${KEYFILE} ${HOMEDIR}/.ssh/${KEYFILE}
USER root
RUN chmod 700 ${HOMEDIR}/.ssh/${KEYFILE} \
    && touch ${HOMEDIR}/.ssh/known_hosts \
    && chown -R ${USERNAME}:${USERNAME} ${HOMEDIR}/.ssh
USER ${USERNAME}


RUN echo "Host gitlab.com\n    HostName gitlab.com\n    IdentityFile ~/.ssh/${KEYFILE}" >> ${HOMEDIR}/.ssh/config \
    && eval "$(ssh-agent -s)" \
    && ssh-add ${HOMEDIR}/.ssh/${KEYFILE} \
    && source ${HOMEDIR}/.bashrc \
    && mkdir -p ${ROSDIR}/src \
    && cd ${ROSDIR}/src \
    && GIT_SSH_COMMAND='ssh -o StrictHostKeyChecking=no -i ${HOMEDIR}/.ssh/${KEYFILE}' git clone git@gitlab.com:reefgen/reefgen-forks/thruster_manager.git -b main

WORKDIR ${ROSDIR}

# Stand up ros2 env and build the easy dependency packages
RUN source /opt/ros/humble/setup.bash && \
    # source ${ROSDIR}/install/setup.bash && \
    colcon build

# allow colcon build to run without sudo
USER root
RUN chown -R ${USERNAME}:${USERNAME} ${ROSDIR}

# Set entrypoint for running ros2 commands
COPY ros_entrypoint.sh /ros_entrypoint.sh
ENTRYPOINT ["/ros_entrypoint.sh"]
CMD ["bash"]