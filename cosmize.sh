#!/bin/sh

# Runs a given Cosmopolitan Libc tool for both x86_64 and aarch64 artifacts.
# Cosmo creates shadow copies of `.o`/`.a` files for each supported architecture,
# so we have to find and process all of them.
set -eu

TOOL=${1}
shift

COSMO_BIN_DIR=$(dirname ${CC})
X86_64_TOOL="${COSMO_BIN_DIR}/x86_64-linux-cosmo-${TOOL}"
${X86_64_TOOL} "$@"

AARCH_64_TOOL="${COSMO_BIN_DIR}/aarch64-linux-cosmo-${TOOL}"
FIRST=1
# Inspired by cosmocc/cosmoar/cosmoinstall/etc.
for arg
do
    if [ $FIRST -eq 1 ]
    then
        set --
        FIRST=0
    fi
    # Don't try to mangle options.
    if [ "${arg}" = "${arg#-}" ]
    then
        arg="$(dirname ${arg})/.aarch64/$(basename ${arg})"
    fi
    set -- "$@" "$arg"
done
${AARCH_64_TOOL} "$@"
