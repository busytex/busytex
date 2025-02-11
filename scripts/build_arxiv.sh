#!/bin/sh

set -eu

export SOURCE_DATE_EPOCH=1234567890

ARXIV_ID=$1
OUT_DIR=${2:-.}

workdir=${OUT_DIR}/${ARXIV_ID}
if [ -d ${workdir}/ ]
then
    rm -r ${workdir}/
fi
mkdir ${workdir}/

printf "Downloading %s\n" ${ARXIV_ID}
curl -JOsS "https://arxiv.org/src/${ARXIV_ID}" --output-dir ${workdir}/
downloaded=$(find ${workdir} -type f)

printf "Unpacking %s\n" "${downloaded}"
# TODO: handle non-tar files
tar xf ${downloaded} -C ${workdir}/

main_file=$(basename $(grep -l '^\\begin{document}' ${workdir}/* | grep -v _))
printf "Using the main file: %s\n" "${main_file}"

DIST=$PWD/dist-native
PDFLATEXFMT=$DIST/pdflatex.fmt
BUSYTEX=$DIST/busytex

export TEXMFDIST=$DIST/texlive/texmf-dist
export TEXMFVAR=$DIST/texlive/texmf-dist/texmf-var
export TEXMFCNF=$TEXMFDIST/web2c
export FONTCONFIG_PATH=$DIST

cd ${workdir}

$BUSYTEX pdflatex --no-shell-escape --interaction nonstopmode --halt-on-error --output-format=pdf --fmt $PDFLATEXFMT "${main_file}" >/dev/null 2>&1
$BUSYTEX bibtex8 --8bit "${main_file%.tex}.aux" >/dev/null 2>&1
$BUSYTEX pdflatex --no-shell-escape --interaction nonstopmode --halt-on-error --output-format=pdf --fmt $PDFLATEXFMT "${main_file}" >/dev/null 2>&1
$BUSYTEX pdflatex --no-shell-escape --interaction nonstopmode --halt-on-error --output-format=pdf --fmt $PDFLATEXFMT "${main_file}" >/dev/null 2>&1
