set -e

# native version
export DIST=$PWD/dist
export TEXMFCNF=$DIST
export TEXMFDIST=$DIST/texlive-basic/texmf-dist
export FONTCONFIG_PATH=$DIST/fontconfig-native
#export FONTCONFIG_FILE=texlive.conf

export LATEXFMT=$DIST/latex.fmt
export BUSYTEX=$DIST/busytex

#export FC_DEBUG=5418
#export FC_DEBUG=1322
#export FC_DEBUG=298
#export FC_DEBUG=290

cd example
echo $TEXMFDIST

$BUSYTEX xetex --interaction=nonstopmode --halt-on-error --no-pdf --fmt=$LATEXFMT example.tex
$BUSYTEX bibtex8 --debug search example.aux
$BUSYTEX xetex --interaction=nonstopmode --halt-on-error --no-pdf --fmt=$LATEXFMT example.tex
$BUSYTEX xetex --interaction=nonstopmode --halt-on-error --no-pdf --fmt=$LATEXFMT example.tex
$BUSYTEX xdvipdfmx example.xdv
