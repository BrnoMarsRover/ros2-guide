#!/usr/bin/env bash
# Creates the distrobox container with ROS 2 Jazzy + Gazebo Harmonic.
#   container/create.sh              create (or tell that it exists)
#   container/create.sh --replace    remove and create again, e.g. after a new image
#   container/create.sh --local      build the image here instead of downloading it
# Options can be combined. Environment: BMR_BOX (name, default bmr),
# BMR_BOX_HOME (container home, default ~/.bmr-home), BMR_IMAGE.
set -euo pipefail

NAME="${BMR_BOX:-bmr}"
BOX_HOME="${BMR_BOX_HOME:-$HOME/.bmr-home}"
IMAGE="${BMR_IMAGE:-ghcr.io/brnomarsrover/ros2-guide:jazzy}"
REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

GREEN=$'\e[1;32m'; YELLOW=$'\e[1;33m'; RED=$'\e[1;31m'; RESET=$'\e[0m'
ok()   { echo "${GREEN}✓${RESET} $*"; }
warn() { echo "${YELLOW}! $*${RESET}"; }
die()  { echo "${RED}ERROR: $*${RESET}" >&2; exit 1; }

REPLACE=false; LOCAL=false
for arg in "$@"; do
    case "$arg" in
        --replace) REPLACE=true ;;
        --local)   LOCAL=true ;;
        -h|--help) sed -n '2,8s/^# \{0,1\}//p' "$0"; exit 0 ;;
        *)         die "unknown option $arg (see --help)" ;;
    esac
done

[ -f /run/.containerenv ] || [ -f /.dockerenv ] && die "run this on the host, not inside a container"

# ---------------------------------------------------------------- distrobox + container engine
install_hint() {
    . /etc/os-release
    case " $ID ${ID_LIKE:-} " in
        *" arch "*)   echo "    sudo pacman -S distrobox podman" ;;
        *" fedora "*) echo "    sudo dnf install distrobox podman" ;;
        *" ubuntu "*|*" debian "*) echo "    sudo apt install distrobox podman" ;;
        *)            echo "    see https://distrobox.it/#installation" ;;
    esac
}
command -v distrobox >/dev/null || { echo "distrobox is missing. Install it:"; install_hint; exit 1; }
if command -v podman >/dev/null; then ENGINE=podman
elif command -v docker >/dev/null; then ENGINE=docker
else echo "podman or docker is missing. Install it:"; install_hint; exit 1
fi
ok "distrobox $(distrobox --version 2>/dev/null | grep -o '[0-9][0-9.]*' | head -1), $ENGINE"

if [ "$ENGINE" = docker ] && ! docker info >/dev/null 2>&1; then
    die "docker does not answer: is it running, and are you in the 'docker' group? (or install podman)"
fi

# ---------------------------------------------------------------- image
if $LOCAL; then
    IMAGE="localhost/ros2-guide:jazzy"
    ok "building $IMAGE (takes a while, ~7 GB)"
    "$ENGINE" build -f "$REPO/container/Dockerfile" -t "$IMAGE" "$REPO"
fi

# ---------------------------------------------------------------- container home
# own dotfiles, but the host's git identity and SSH keys: the team repositories are private
mkdir -p "$BOX_HOME"
if [ -d "$HOME/.ssh" ] && [ ! -e "$BOX_HOME/.ssh" ]; then
    ln -s "$HOME/.ssh" "$BOX_HOME/.ssh"
    ok "SSH keys shared from ~/.ssh"
fi
# the host's git config included, team repositories over SSH; idempotent, git lfs adds its own lines
cfg="$BOX_HOME/.gitconfig"
for inc in "$HOME/.gitconfig" "${XDG_CONFIG_HOME:-$HOME/.config}/git/config"; do
    git config --file "$cfg" --get-all include.path | grep -qxF "$inc" ||
        git config --file "$cfg" --add include.path "$inc"
done
git config --file "$cfg" url."git@github.com:BrnoMarsRover/".insteadOf https://github.com/BrnoMarsRover/
ok "git: the host's config + BrnoMarsRover repositories over SSH"

# ---------------------------------------------------------------- container
if distrobox list --no-color 2>/dev/null | awk -F'|' '{gsub(/ /,"",$2); print $2}' | grep -qx "$NAME"; then
    if $REPLACE; then
        warn "removing the container $NAME (the home $BOX_HOME and your code stay)"
        distrobox rm --force "$NAME"
    else
        ok "container $NAME already exists: distrobox enter $NAME"
        echo "  (new image? container/create.sh --replace)"
        exit 0
    fi
fi

FLAGS=()
# NVIDIA: the host driver is shared into the container; AMD/Intel work through /dev/dri
if command -v nvidia-smi >/dev/null && nvidia-smi -L >/dev/null 2>&1; then
    FLAGS+=(--nvidia)
    ok "NVIDIA GPU found, sharing the driver"
fi

ok "creating $NAME from $IMAGE (the first download is a few GB)"
# --home: the container has its own dotfiles (bmr-system/setup.sh changes ~/.bashrc, ~/.tmux.conf);
# the host home stays visible at its usual path, so the code can live there
distrobox create --yes --name "$NAME" --image "$IMAGE" --home "$BOX_HOME" "${FLAGS[@]}" \
    $($LOCAL || echo --pull)

ok "first start (sets up the user, takes a minute)"
distrobox enter "$NAME" -- true

echo
ok "done. Enter the container and check it:"
echo "    distrobox enter $NAME"
echo "    $REPO/container/check.sh"
