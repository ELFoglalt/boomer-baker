#! /bin/bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
source "${SCRIPT_DIR}/src/utils.sh"

# Baked servers
rm -rf "${BAKES_DIR}"

# PR Patches
rm -rf "${PATCHES_DIR}"

# Misc
rm -rf "${PROJECT_DIR}/updater_output.log"
