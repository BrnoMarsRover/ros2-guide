#!/usr/bin/env bash
# Checks the ROS 2 environment; run it inside the container (distrobox enter bmr).
#   container/check.sh          ROS, communication, graphics, Gazebo
#   container/check.sh --gui    also opens turtlesim for a few seconds
#   container/check.sh --headless  no graphics checks (CI)
# Ends with a summary to paste into the chat when something fails.
set -uo pipefail

GREEN=$'\e[1;32m'; YELLOW=$'\e[1;33m'; RED=$'\e[1;31m'; RESET=$'\e[0m'
FAILED=0; WARNED=0
ok()   { echo "${GREEN}✓${RESET} $*"; }
warn() { echo "${YELLOW}! $*${RESET}"; WARNED=$((WARNED + 1)); }
fail() { echo "${RED}✗ $*${RESET}"; FAILED=$((FAILED + 1)); }

GUI=false; HEADLESS=false
case "${1:-}" in --gui) GUI=true ;; --headless) HEADLESS=true ;; esac
# the script also works from a shell that did not source ROS
[ -n "${ROS_DISTRO:-}" ] || { set +u; . /etc/bmr-ros.sh 2>/dev/null; set -u; }
LOG="$(mktemp -d /tmp/bmr_check.XXXX)"

# ---------------------------------------------------------------- system
. /etc/os-release
if [ -f /run/.containerenv ] || [ -f /.dockerenv ]; then ok "inside a container ($PRETTY_NAME)"
elif [ "$VERSION_ID" = 24.04 ]; then ok "native $PRETTY_NAME"
else fail "not inside the container: run 'distrobox enter bmr' first"; fi

# ---------------------------------------------------------------- ROS
if command -v ros2 >/dev/null && [ "${ROS_DISTRO:-}" = jazzy ]; then ok "ROS 2 $ROS_DISTRO"
else fail "ROS 2 Jazzy not found (is /etc/bmr-ros.sh sourced? open a new terminal)"; fi
info_range="${ROS_AUTOMATIC_DISCOVERY_RANGE:-SUBNET}"
if [ "$info_range" = LOCALHOST ]; then ok "ROS communicates only within this computer"
else warn "ROS_AUTOMATIC_DISCOVERY_RANGE=$info_range: nodes on the network (the rover!) are visible"; fi

# talker -> listener: discovery and messages work
# setsid: "ros2 run" starts the node as a child, so we stop the whole process group
setsid ros2 run demo_nodes_py talker > "$LOG/talker.log" 2>&1 &
talker=$!
if timeout 20 ros2 topic echo --once /chatter > "$LOG/echo.log" 2>&1; then ok "a node received a message from another node"
else fail "no message from the talker node (see $LOG)"; fi
kill -- -$talker 2>/dev/null; wait $talker 2>/dev/null

# ---------------------------------------------------------------- graphics
if $HEADLESS; then :
elif [ -n "${WAYLAND_DISPLAY:-}${DISPLAY:-}" ]; then ok "display: ${DISPLAY:+DISPLAY=$DISPLAY }${WAYLAND_DISPLAY:+WAYLAND_DISPLAY=$WAYLAND_DISPLAY}"
else fail "no display (DISPLAY / WAYLAND_DISPLAY): windows will not open"; fi

RENDERER="$(glxinfo -B 2>/dev/null | sed -n 's/.*OpenGL renderer string: //p')"
$HEADLESS || case "$RENDERER" in
    "")                    fail "OpenGL does not work (glxinfo -B)" ;;
    *llvmpipe*|*softpipe*) warn "OpenGL without GPU ($RENDERER): rviz2 is OK, Gazebo will be slow" ;;
    *)                     ok "GPU: $RENDERER" ;;
esac

if $GUI; then
    setsid ros2 run turtlesim turtlesim_node > "$LOG/turtlesim.log" 2>&1 &
    turtle=$!
    sleep 6
    if kill -0 $turtle 2>/dev/null; then ok "turtlesim ran (did you see the window?)"
    else fail "turtlesim crashed (see $LOG/turtlesim.log)"; fi
    kill -- -$turtle 2>/dev/null; wait $turtle 2>/dev/null
fi

# ---------------------------------------------------------------- Gazebo
if GZ_VERSION_OUT="$(gz sim --versions 2>/dev/null)" && [ -n "$GZ_VERSION_OUT" ]; then
    ok "Gazebo $GZ_VERSION_OUT"
    # a short headless simulation: the physics and the plugins load
    if timeout 120 gz sim -s -r --iterations 500 empty.sdf > "$LOG/gz.log" 2>&1; then ok "Gazebo simulates (headless)"
    else fail "headless Gazebo did not finish (see $LOG/gz.log)"; fi
else
    fail "Gazebo (gz sim) not found"
fi

# ---------------------------------------------------------------- GitHub
# team repositories are private: SSH key on GitHub + member of BrnoMarsRover (needed from chapter 8)
if ! $HEADLESS; then
    if GH="$(ssh -T -o BatchMode=yes -o ConnectTimeout=10 git@github.com 2>&1)"; [[ "$GH" == *"successfully authenticated"* ]]; then
        ok "GitHub over SSH: $(echo "$GH" | grep -o 'Hi [^!]*')"
        if git ls-remote https://github.com/BrnoMarsRover/simulation.git HEAD >/dev/null 2>&1; then ok "access to the team repositories"
        else warn "no access to the team repositories yet: ask to be added to github.com/BrnoMarsRover"; fi
    else
        warn "GitHub over SSH does not work yet (needed from chapter 8, see chapter 0)"
    fi
fi

# ---------------------------------------------------------------- summary
HOST="unknown"; [ -f /run/host/etc/os-release ] && HOST="$(. /run/host/etc/os-release && echo "$PRETTY_NAME")"
echo
echo "---- summary (paste this when asking for help) ----"
echo "host:      $HOST"
echo "container: $PRETTY_NAME, ROS ${ROS_DISTRO:-?}, $(gz sim --versions 2>/dev/null | head -1 | sed 's/^/Gazebo /')"
echo "session:   ${XDG_SESSION_TYPE:-?}, DISPLAY=${DISPLAY:-}, WAYLAND_DISPLAY=${WAYLAND_DISPLAY:-}"
echo "renderer:  ${RENDERER:-none}"
echo "result:    $FAILED failed, $WARNED warnings"
echo "---------------------------------------------------"
[ $FAILED -eq 0 ] && echo "${GREEN}All set.${RESET}" || echo "${RED}Something is wrong, see above.${RESET}"
exit $FAILED
