set -e

export DIST=$PWD/dist-native
export TEXMFDIST=$DIST/texlive/texmf-dist
export TEXMFVAR=$DIST/texlive/texmf-dist/texmf-var
export TEXMFCNF=$TEXMFDIST/web2c
export FONTCONFIG_PATH=$DIST

export LATEXFMT=$DIST/latex.fmt
export BUSYTEX=$DIST/busytex

cd example

$BUSYTEX xetex --interaction nonstopmode --halt-on-error --no-pdf --fmt $LATEXFMT example.tex
$BUSYTEX bibtex8 --8bit example.aux
$BUSYTEX xetex --interaction nonstopmode --halt-on-error --no-pdf --fmt $LATEXFMT example.tex
$BUSYTEX xetex --interaction nonstopmode --halt-on-error --no-pdf --fmt $LATEXFMT example.tex
$BUSYTEX xdvipdfmx -o example.pdf example.xdv
