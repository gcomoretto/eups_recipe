#!/bin/bash

EUPS_HOME="${PREFIX}/eups"
EUPS_SRC="${EUPS_HOME}/src"
LSST_EUPS_VERSION="2.1.5"
LSST_EUPS_TARURL="https://github.com/RobertLuptonTheGood/eups/archive/${LSST_EUPS_VERSION}.tar.gz"
EUPS_DIR="${EUPS_HOME}/${LSST_EUPS_VERSION}"
export EUPS_PATH="${EUPS_HOME}/stack_default"

EUPS_PYTHON=$PYTHON  # use PYTHON in the host env for eups

# tell it where CURL is
CURL="${PREFIX}/bin/curl"
# disable curl progress meter unless running under a tty -- this is intended
# to reduce the amount of console output when running under CI
CURL_OPTS='-#'
if [[ ! -t 1 ]]; then
    CURL_OPTS='-sS'
fi

###############################################################################
# actual eups build

mkdir -p ${EUPS_HOME}

# Install EUPS
echo "
Installing EUPS (${LSST_EUPS_VERSION})..."
echo "Using python at ${EUPS_PYTHON} to install EUPS"
# echo "Configured EUPS_PKGROOT: ${EUPS_PKGROOT}"

mkdir -p ${EUPS_SRC}
cd ${EUPS_SRC}

"$CURL" "$CURL_OPTS" -L "$LSST_EUPS_TARURL" | tar xzvf -

pushd "eups-${LSST_EUPS_VERSION}"

mkdir -p "${EUPS_PATH}"/{site,ups_db}
touch "${EUPS_PATH}/ups_db/.conda_keep"
mkdir -p "${EUPS_DIR}"
./configure \
    --prefix="${EUPS_DIR}" \
    --with-eups="${EUPS_PATH}" \
    --with-python="${EUPS_PYTHON}"
make install

# eups installs readonly, need to give permission to the user in order to complete the packaging
chmod -R a+r "${EUPS_DIR}"
chmod -R u+w "${EUPS_DIR}"

rm -rf "${EUPS_SRC}" # I don't want the src folder in the conda package

# Copy the [de]activate scripts to $PREFIX/etc/conda/[de]activate.d.
# This will allow them to be run on environment activation.
for CHANGE in "activate" "deactivate"
do
    mkdir -p "${PREFIX}/etc/conda/${CHANGE}.d"
    cp "${RECIPE_DIR}/${CHANGE}.sh" "${PREFIX}/etc/conda/${CHANGE}.d/${PKG_NAME}_${CHANGE}.sh"
done
