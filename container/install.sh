#!/usr/bin/env bash
# ROS 2 Jazzy + Gazebo Harmonic + tools on Ubuntu 24.04.
#   sudo container/install.sh
# Used by the Dockerfile (the container image) and directly on native Ubuntu / WSL2.
# Installs the same as steps 1-3 of bmr-system/setup.sh (keep in sync with its
# SYSTEMS and APT_TOOLS), so setup.sh later only finds everything installed.
set -euo pipefail

[ "$(id -u)" -eq 0 ] || { echo "run as root: sudo $0" >&2; exit 1; }
. /etc/os-release
[ "$VERSION_ID" = 24.04 ] || { echo "Ubuntu 24.04 needed, this is $PRETTY_NAME" >&2; exit 1; }

export DEBIAN_FRONTEND=noninteractive
APT="apt-get -o Acquire::Retries=5"

# bmr-system: APT_TOOLS
BMR_TOOLS=(
    git git-lfs build-essential cmake python3-pip
    python3-rosdep python3-vcstool python3-colcon-common-extensions
    tmux tmuxinator fonts-powerline
)
# the guide: teleop, TF tools, GPU check, an editor in the terminal
GUIDE_TOOLS=(
    ros-jazzy-teleop-twist-keyboard ros-jazzy-rqt-tf-tree ros-jazzy-tf2-tools
    mesa-utils nano bash-completion
)

# ---------------------------------------------------------------- base (setup.sh: install_base)
$APT update
$APT install -y --no-install-recommends ca-certificates curl gnupg locales software-properties-common
add-apt-repository -y universe >/dev/null
locale-gen en_US.UTF-8 >/dev/null

# ---------------------------------------------------------------- apt sources (setup.sh: install_ros)
if ! grep -rqs "packages.ros.org/ros2" /etc/apt/sources.list /etc/apt/sources.list.d/; then
    version="$(curl -fsSL https://api.github.com/repos/ros-infrastructure/ros-apt-source/releases/latest \
               | grep -F '"tag_name"' | awk -F'"' '{print $4}')"
    curl -fsSL -o /tmp/ros2-apt-source.deb \
        "https://github.com/ros-infrastructure/ros-apt-source/releases/download/$version/ros2-apt-source_$version.${UBUNTU_CODENAME}_all.deb"
    dpkg -i /tmp/ros2-apt-source.deb
    rm -f /tmp/ros2-apt-source.deb
fi
if ! grep -rqs "packages.osrfoundation.org/gazebo" /etc/apt/sources.list /etc/apt/sources.list.d/; then
    key=/usr/share/keyrings/pkgs-osrf-archive-keyring.gpg
    curl -fsSL https://packages.osrfoundation.org/gazebo.gpg -o "$key"
    echo "deb [arch=$(dpkg --print-architecture) signed-by=$key] http://packages.osrfoundation.org/gazebo/ubuntu-stable $UBUNTU_CODENAME main" \
        > /etc/apt/sources.list.d/gazebo-stable.list
fi

# ---------------------------------------------------------------- packages (setup.sh: install_ros, install_tools)
$APT update
$APT install -y ros-jazzy-desktop ros-jazzy-ros-gz "${BMR_TOOLS[@]}" "${GUIDE_TOOLS[@]}"
git lfs install --system --skip-repo >/dev/null
[ -f /etc/ros/rosdep/sources.list.d/20-default.list ] || rosdep init

# ---------------------------------------------------------------- shell
# every interactive bash: ROS sourced, guide defaults; bmr-system's env.sh later adds the workspaces
cat > /etc/bmr-ros.sh <<'EOF'
# ROS 2 environment of the BMR guide (container/install.sh)
# ROS talks only to this computer, not to the rover or other laptops on the same network.
# Chapter 8 explains how to change it. Set before sourcing: setup.bash keeps a set value.
export ROS_AUTOMATIC_DISCOVERY_RANGE="${ROS_AUTOMATIC_DISCOVERY_RANGE:-LOCALHOST}"
. /opt/ros/jazzy/setup.bash
export GZ_VERSION=harmonic
# rviz2 and Gazebo are more reliable through XWayland than native Wayland
export QT_QPA_PLATFORM="${QT_QPA_PLATFORM:-xcb}"
EOF
grep -qF /etc/bmr-ros.sh /etc/bash.bashrc || echo '[ -f /etc/bmr-ros.sh ] && . /etc/bmr-ros.sh' >> /etc/bash.bashrc

echo "done: ROS 2 Jazzy + Gazebo Harmonic. Open a new terminal."
