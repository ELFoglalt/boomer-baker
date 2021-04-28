#! /bin/bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
source "${SCRIPT_DIR}/src/utils.sh"

if [[ $# -ne 1 ]] && [[ $# -ne 3 ]] && [[ $# -ne 4 ]]
then
    echo "usage: serve.sh server_dir [network_mask server_ip [game_port]]"
    exit 1
fi

SERVER_DIR=$(realpath ${1:-server})
if [ ! -d "${SERVER_DIR}" ]; then
    echo "Can not find input folder ${1}"
    exit 1
fi
SERVERSETTINGS="${SERVER_DIR}/mods/pr/settings/serversettings.con"
DOCKERFILE="${DOCKER_DIR}/Dockerfile"

# Set the port and ip to a dev port
NETWORK_SUBNET=${2:-192.168.200.0/24}
SERVER_IP=${3:-192.168.200.2}
GAME_PORT=${4:-16567}

# Store the current IP and port from the config
ORIGINAL_IP=$(sed -nE "s|sv.serverIP \"(.*)\"$|\1|p" "${SERVERSETTINGS}")
ORIGINAL_PORT=$(sed -nE "s|sv.serverPort (.*)$|\1|p" "${SERVERSETTINGS}")

# Overwrite it with the dev IP and port
sed -Ei "s|(sv.serverIP \").*(\")|\1${SERVER_IP}\2|" "${SERVERSETTINGS}"
sed -Ei "s|(sv.serverPort ).*$|\1${GAME_PORT}|" "${SERVERSETTINGS}"

# The original IP and port are restored upon exit
function cleanup1 {
    sed -Ei "s|(sv.serverIP \").*(\")$|\1${ORIGINAL_IP}\2|" "${SERVERSETTINGS}"
    sed -Ei "s|(sv.serverPort ).*$|\1${ORIGINAL_PORT}|" "${SERVERSETTINGS}"
}
trap cleanup1 EXIT

# Build the dev server docker image
docker build \
    --tag prserver-dev \
    --build-arg GAME_PORT=${GAME_PORT} \
    ${DOCKER_DIR}

# We create a dedicated network for the container to run in
# (running the container in the bridge network doesn't always work)
NETWORK_NAME="prserver-dev-network"

# Delete the network if it already exists
NETWORK=$(docker network ls -q -f name="$NETWORK_NAME")
echo $NETWORK
if [ ! -z "${NETWORK}" ]
then
    docker network rm $NETWORK
fi
# Create the network
docker network create --subnet=${NETWORK_SUBNET} ${NETWORK_NAME}

# Make sure the network gets deleted on exit
function cleanup2 {
    cleanup1
    NETWORK=$(docker network ls -q -f name=${NETWORK_NAME})
    docker network rm $NETWORK
}
trap cleanup2 EXIT

docker run \
    --mount \
        type=bind,source="${SERVER_DIR}",target="/server/mnt" \
    --network ${NETWORK_NAME} \
    --ip ${SERVER_IP} \
    --publish ${GAME_PORT}:${GAME_PORT}/udp \
    --publish 27900:27900/udp \
    --publish 29900:29900/udp \
    --publish 4711:4711/tcp \
    --publish 4712:4712/tcp \
    --env PRB_MODULE_MODE=DEBUG \
    --rm \
    --interactive \
    --tty \
    prserver-dev
