set -e

export DIST=$PWD/dist
export TEXMFCNF=$DIST/texlive-basic/texmf-dist/web2c
export TEXMFDIST=$DIST/texlive-basic/texmf-dist
export TEXMFVAR=$DIST/texlive-basic/texmf-var
export FONTCONFIG_PATH=$DIST

export LATEXFMT=$DIST/latex.fmt
export BUSYTEX=$DIST/busytex

cd example

$BUSYTEX xetex --interaction nonstopmode --halt-on-error --no-pdf --fmt $LATEXFMT example.tex
$BUSYTEX bibtex8 --8bit example.aux
$BUSYTEX xetex --interaction nonstopmode --halt-on-error --no-pdf --fmt $LATEXFMT example.tex
$BUSYTEX xetex --interaction nonstopmode --halt-on-error --no-pdf --fmt $LATEXFMT example.tex
$BUSYTEX xdvipdfmx -o example.pdf example.xdv
