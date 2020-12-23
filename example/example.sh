set -e

export DIST=$PWD/dist-native
export TEXMFDIST=$DIST/texlive/texmf-dist
export TEXMFVAR=$DIST/texlive/texmf-dist/texmf-var
export TEXMFCNF=$TEXMFDIST/web2c
export FONTCONFIG_PATH=$DIST

export XETEXFMT=$DIST/xelatex.fmt
export PDFTEXFMT=$DIST/pdflatex.fmt
export LUATEXFMT=$DIST/lualatex.fmt
export BUSYXETEX=$DIST/busytex_xetex
export BUSYPDFTEX=$DIST/busytex_pdftex

cd example

$BUSYXETEX xetex --interaction nonstopmode --halt-on-error --no-pdf --fmt $XETEXFMT example.tex
$BUSYXETEX bibtex8 --8bit example.aux
$BUSYXETEX xetex --interaction nonstopmode --halt-on-error --no-pdf --fmt $XETEXFMT example.tex
$BUSYXETEX xetex --interaction nonstopmode --halt-on-error --no-pdf --fmt $XETEXFMT example.tex
$BUSYXETEX xdvipdfmx -o example.pdf example.xdv
mv example.pdf example_xetex.pdf

$BUSYPDFTEX pdftex --interaction nonstopmode --halt-on-error --no-pdf --fmt $PDFTEXFMT example.tex
$BUSYPDFTEX bibtex8 --8bit example.aux
$BUSYPDFTEX pdftex --interaction nonstopmode --halt-on-error --no-pdf --fmt $PDFTEXFMT example.tex
$BUSYPDFTEX pdftex --interaction nonstopmode --halt-on-error --no-pdf --fmt $PDFTEXFMT example.tex
mv example.pdf example_pdftex.pdf

#$BUSYTEX luatex --interaction nonstopmode --halt-on-error --no-pdf --fmt $LATEXFMT example.tex
#$BUSYTEX bibtex8 --8bit example.aux
#$BUSYTEX luatex --interaction nonstopmode --halt-on-error --no-pdf --fmt $LATEXFMT example.tex
#$BUSYTEX luatex --interaction nonstopmode --halt-on-error --no-pdf --fmt $LATEXFMT example.tex
#mv example.pdf example_luatex.pdf
