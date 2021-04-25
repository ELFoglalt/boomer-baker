#!/bin/bash

# strict mode
set -eou pipefail
IFS=$'\n\t'
# see http://redsymbol.net/articles/unofficial-bash-strict-mode/

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

if [ $# -le 1 ] || [ $# -gt 3 ]
then
    echo "usage: bake.sh server_zip server_ip [port]"
    exit 1
fi

SERVER_ZIP=$(realpath ${1})
if [ ! -f "${SERVER_ZIP}" ]; then
    echo "Can not find input file ${1}"
    exit 1
fi
if [ ! -f "${SCRIPT_DIR}/license.key" ]; then
    echo "Missing license.key"
    exit 1
fi

SERVER_IP=${2}
SERVER_PORT=${3:-16567}

VERSION_NAME=${SERVER_ZIP##*/} # Strip leading directories
VERSION_NAME=${VERSION_NAME%.zip} # Strip extension
OUTPUT_DIR="${SCRIPT_DIR}/bakes/prbf2_unknown_server"
DOWNLOAD_DIR="${SCRIPT_DIR}/patches"
UPDATER_OUTPUT="${SCRIPT_DIR}/updater_output.log"
SERVERSETTINGS="${SERVER_DIR}/mods/pr/settings/serversettings.con"

UNAME=$(uname)
if [ "$UNAME" == "Linux" ] ; then
	PRSERVERUPDATER="prserverupdater-linux64"
elif [[ "$UNAME" == CYGWIN* || "$UNAME" == MINGW* ]] ; then
	PRSERVERUPDATER="prserverupdater-win32.exe"
    set +e
    net session > /dev/null 2>&1
    if [ $? -ne 0 ]
    then
        echo "Prseverupdater requires administrative privileges on windows. Please run your terminal as admin!"
        exit 0
    fi
    set -e
elif [ "$UNAME" == "Darwin" ] ; then
	echo "Baking on mac is not supported, duh."
    exit 1
else
    echo "Failed to determine which serverupdater to use"
    exit 1
fi

# Unzip game files
rm -rf "${OUTPUT_DIR}"
mkdir -p "${OUTPUT_DIR}"
unzip -o "${SERVER_ZIP}" -d "${OUTPUT_DIR}"

# Copy license
cp "${SCRIPT_DIR}/license.key" "${OUTPUT_DIR}/mods/pr"
# Edit server IP and port in serversettings.con
sed -Ei "s|(sv.serverIP \").*(\")|\1${SERVER_IP}\2|" "${SERVERSETTINGS}"
sed -Ei "s|(sv.serverPort ).*$|\1${SERVER_PORT}|" "${SERVERSETTINGS}"

# Add execute rights on Linux
if [ "$UNAME" == "Linux" ]
then
    chmod +x "${OUTPUT_DIR}/start_pr.sh"
    chmod +x "${OUTPUT_DIR}/bin/amd-64/prbf2_l64ded"
    chmod +x "${OUTPUT_DIR}/mods/pr/bin/${PRSERVERUPDATER}"
    chmod +x "${OUTPUT_DIR}/mods/pr/bin/PRMurmur/createchannel.sh"
    chmod +x "${OUTPUT_DIR}/mods/pr/bin/PRMurmur/initialsetup.sh"
    chmod +x "${OUTPUT_DIR}/mods/pr/bin/PRMurmur/prmurmurd.x64"
    chmod +x "${OUTPUT_DIR}/mods/pr/bin/PRMurmur/startmumo.sh"
fi


if [[ "$UNAME" == CYGWIN* || "$UNAME" == MINGW* ]]
then
    mkdir -p ${DOWNLOAD_DIR}
fi

pushd "${OUTPUT_DIR}/mods/pr/bin"
# Setting the patches directory doesn't work on linux, but it does on windows.
# On linux the updater always puts the files in /tmp.
export PR_DOWNLOAD_DIR="${DOWNLOAD_DIR}"

# Run the server updater
if [ "$UNAME" == "Linux" ]
then
    PRSERVERUPDATER_COMMAND="./${PRSERVERUPDATER}"
else
    PRSERVERUPDATER_COMMAND="winpty ./${PRSERVERUPDATER}"
fi
echo -ne '\n' | "./${PRSERVERUPDATER}" | tee "${UPDATER_OUTPUT}"
popd

# Restore server IP and PORT to defaults serversettings.con
# This is done so the files can be copied as is, and the changes won't be reflected
# in the server repository.
sed -nEi "s|(sv.serverIP \").*(\")|\1\2|" "${OUTPUT_DIR}/mods/pr/settings/serversettings.con"
sed -nEi "s|(sv.serverPort ).*|\116567|" "${OUTPUT_DIR}/mods/pr/settings/serversettings.con"
# Remove license file
rm "${OUTPUT_DIR}/mods/pr/license.key"

# Remove .original files if any
shopt -s nullglob
shopt -s globstar
rm -f -- ${OUTPUT_DIR}/**/*.original

# Name output bake and clean up
sed -n -r 's/\x1B\[(;?[0-9]{1,3})+[mGK]//g' "${UPDATER_OUTPUT}" # Strip out color
NEW_VERSION=$(grep -oP "(?<=Successfully updated to )[0-9\.]+" "${UPDATER_OUTPUT}")
RESULT_DIR="${OUTPUT_DIR/unknown/$NEW_VERSION}_baked"
mv "${OUTPUT_DIR}" "${RESULT_DIR}"
rm -f "${UPDATER_OUTPUT}"

echo ""
du --summarize --human-readable ${RESULT_DIR}
