set -e

export DIST=$PWD/dist-native
export XETEXFMT=$DIST/xelatex.fmt
export PDFTEXFMT=$DIST/pdflatex.fmt
export LUATEXFMT=$DIST/lualatex.fmt
export BUSYXETEX=$DIST/busytex
export BUSYPDFTEX=$DIST/busytex
export BUSYLUATEX=$DIST/busytex

export TEXMFDIST=$DIST/texlive/texmf-dist
export TEXMFVAR=$DIST/texlive/texmf-dist/texmf-var
export TEXMFCNF=$TEXMFDIST/web2c
export FONTCONFIG_PATH=$DIST

cd example

$BUSYXETEX xetex --no-shell-escape --interaction nonstopmode --halt-on-error --no-pdf --fmt $XETEXFMT example.tex
$BUSYXETEX bibtex8 --8bit example.aux
$BUSYXETEX xetex --no-shell-escape --interaction nonstopmode --halt-on-error --no-pdf --fmt $XETEXFMT example.tex
$BUSYXETEX xetex --no-shell-escape --interaction nonstopmode --halt-on-error --no-pdf --fmt $XETEXFMT example.tex
$BUSYXETEX xdvipdfmx -o example_xetex.pdf example.xdv
rm example.aux

$BUSYPDFTEX pdftex --no-shell-escape --interaction nonstopmode --halt-on-error --output-format=pdf --fmt $PDFTEXFMT example.tex
$BUSYPDFTEX bibtex8 --8bit example.aux
$BUSYPDFTEX pdftex --no-shell-escape --interaction nonstopmode --halt-on-error --output-format=pdf --fmt $PDFTEXFMT example.tex
$BUSYPDFTEX pdftex --no-shell-escape --interaction nonstopmode --halt-on-error --output-format=pdf --fmt $PDFTEXFMT example.tex
mv example.pdf example_pdftex.pdf
rm example.aux

#$BUSYLUATEX luatex --no-shell-escape --interaction nonstopmode --halt-on-error --output-format=pdf --fmt $LUATEXFMT example.tex
#$BUSYLUATEX bibtex8 --8bit example.aux                                           
#$BUSYLUATEX luatex --no-shell-escape --interaction nonstopmode --halt-on-error --output-format=pdf --fmt $LUATEXFMT example.tex
#$BUSYLUATEX luatex --no-shell-escape --interaction nonstopmode --halt-on-error --output-format=pdf --fmt $LUATEXFMT example.tex
#mv example.pdf example_luatex.pdf
#rm example.aux
