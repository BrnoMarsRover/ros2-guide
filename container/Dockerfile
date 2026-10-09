# Image for distrobox: Ubuntu 24.04 + ROS 2 Jazzy + Gazebo Harmonic + tools.
#   docker build -f container/Dockerfile -t ros2-guide:jazzy .
FROM ubuntu:24.04

LABEL org.opencontainers.image.source="https://github.com/BrnoMarsRover/ros2-guide" \
      org.opencontainers.image.description="BMR ROS 2 guide: Ubuntu 24.04, ROS 2 Jazzy, Gazebo Harmonic" \
      com.github.containers.toolbox="true"

# the image's user 'ubuntu' has UID 1000, which distrobox needs for the host user
RUN userdel -r ubuntu 2>/dev/null || true

COPY container/install.sh /tmp/install.sh
RUN bash /tmp/install.sh && rm -f /tmp/install.sh

# packages distrobox would otherwise install on the first start
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        bc bzip2 diffutils dialog findutils gpg hostname iproute2 iputils-ping keyutils \
        less libcap2-bin libegl1 libgl1 libkrb5-3 libnss-mdns libnss-myhostname libvulkan1 \
        lsof man-db manpages mesa-vulkan-drivers ncurses-base openssh-client passwd pigz \
        pinentry-curses procps rsync sudo time tree tzdata unzip util-linux wget xauth \
        xz-utils zip \
    && rm -rf /var/lib/apt/lists/*

# prompt "(bmr)user@host": Ubuntu's ~/.bashrc shows /etc/debian_chroot, so one sees where they are
RUN echo bmr > /etc/debian_chroot
