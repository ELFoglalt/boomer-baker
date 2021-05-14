# strict mode
# see http://redsymbol.net/articles/unofficial-bash-strict-mode/
set -eou pipefail
IFS=$'\n\t'

# Constants
export SRC_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
export PROJECT_DIR=$(realpath "${SRC_DIR}/../..")
export BAKES_DIR="${PROJECT_DIR}/bakes"
export PATCHES_DIR="${PROJECT_DIR}/patches"
export DOCKER_DIR="${PROJECT_DIR}/docker"
export TEMP_DIR="${PROJECT_DIR}/temp"

mkdir -p "${TEMP_DIR}"

# Silent pushd and popd
function pushd {
    command pushd "$@" > /dev/null
}
function popd {
    command popd "$@" > /dev/null
}
