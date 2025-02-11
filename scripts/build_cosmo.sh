#!/bin/sh

# This script is provided for convenience in case
# you want to build a Cosmopolitan binary locally.
# It is not used when preparing releases.
#
# Run it as: ./build_cosmo.sh PATH_TO_COSMOCC_TOOLCHAIN

set -eu

COSMODIR=$1/bin

CC="${COSMODIR}/cosmocc" \
CXX="${COSMODIR}/cosmoc++" \
AR="${COSMODIR}/cosmoar" \
INSTALL="${COSMODIR}/cosmoinstall" \
make native
