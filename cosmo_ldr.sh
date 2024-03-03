#!/bin/sh

# `ld -r` for Cosmo.

set -eu

COSMIZE=${1}
shift

# For Cosmo builds, this section is auto-generated by `gcc` when
# `-fpatchable-function-entry=...` is used for `--ftrace` support.
# The section is actually unused, and will eventually be removed by
# the Cosmo linker script when linking the final binary.
# However, we need to remove them right here, otherwise a relocation
# corresponding to one of the entries might reference a COMDAT group
# from a C++ file (for example, in XeTeX) that is discarded on `ld -r`.
# This leads to a linker warning in `ld.lld` and an error in `ld.bfd`.
for arg
do
    if [ "${arg}" = "${arg#-}" ]
    then
        ${COSMIZE} objcopy --remove-section=__patchable_function_entries "${arg}"
    fi
done

${COSMIZE} ld -r $@
