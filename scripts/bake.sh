#!/bin/bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
source "${SCRIPT_DIR}/src/utils.sh"

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
LICENSE_KEY="${PROJECT_DIR}/license.key"
if [ ! -f "${LICENSE_KEY}" ]; then
    echo "Missing license.key"
    exit 1
fi

SERVER_IP=${2}
SERVER_PORT=${3:-16567}

VERSION_NAME=${SERVER_ZIP##*/} # Strip leading directories
VERSION_NAME=${VERSION_NAME%.zip} # Strip extension
OUTPUT_DIR="${BAKES_DIR}/prbf2_unknown_server"
DOWNLOAD_DIR="${PATCHES_DIR}"
UPDATER_OUTPUT="${PROJECT_DIR}/updater_output.log"
SERVERSETTINGS="${OUTPUT_DIR}/mods/pr/settings/serversettings.con"

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
cp "${LICENSE_KEY}" "${OUTPUT_DIR}/mods/pr"
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
sed -Ei "s|(sv.serverIP \").*(\")|\1\2|" "${OUTPUT_DIR}/mods/pr/settings/serversettings.con"
sed -Ei "s|(sv.serverPort ).*|\116567|" "${OUTPUT_DIR}/mods/pr/settings/serversettings.con"
# Remove license file
rm -f "${OUTPUT_DIR}/mods/pr/license.key"

# Remove .original files if any
shopt -s nullglob
shopt -s globstar
rm -f -- ${OUTPUT_DIR}/**/*.original

# Turn off prism (doesn't work out of the box)
ADMIN_CONF="${OUTPUT_DIR}/mods/pr/python/game/realityconfig_admin.py"
sed -Ei "s|(rcon_enabled = )True$|\1False|" "${ADMIN_CONF}"

# Create a .gitignore file in the server folder
readonly GITIGNORE_TEMPLATE=$(realpath "${PROJECT_DIR}/.gitignore.template")
readonly GITINGORE=$(realpath "${OUTPUT_DIR}/.gitignore")
cp ${GITIGNORE_TEMPLATE} ${GITINGORE}
# Append all provided .pyc/.pyd/.pyo file names with negated rules.
pushd "${OUTPUT_DIR}"
while IFS= read -r -d '' file; do
    # The "!" at the start means these files **will** get committed.
    printf "!${file:2}\n" >> ${GITINGORE}
done < <(find . -name "*.py[cdo]" -print0)
popd

# Create a .gitattributes file for git LFS
readonly GITATTRIBUTES_TEMPLATE=$(realpath "${PROJECT_DIR}/.gitattributes.template")
cp "${GITATTRIBUTES_TEMPLATE}" "${OUTPUT_DIR}/.gitattributes"

# Name output bake according to version reported by prserverupdater
sed -n -r 's/\x1B\[(;?[0-9]{1,3})+[mGK]//g' "${UPDATER_OUTPUT}" # Strip out color
NEW_VERSION=$(grep -oP "(?<=Successfully updated to )[0-9\.]+" "${UPDATER_OUTPUT}")
RESULT_DIR="${OUTPUT_DIR/unknown/$NEW_VERSION}_baked"
mv "${OUTPUT_DIR}" "${RESULT_DIR}"

# Clean up prserverupdater output logs
rm -f "${UPDATER_OUTPUT}"

echo ""
echo "Finished bake as"
echo "    $(basename ${RESULT_DIR})" "(" $(du --summarize --human-readable "${RESULT_DIR}" | cut -f -1 ) ")"
echo ""
