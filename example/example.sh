set -e

DIST=$PWD/dist-native
XELATEXFMT=$DIST/xelatex.fmt
PDFLATEXFMT=$DIST/pdflatex.fmt
LUAHBLATEXFMT=$DIST/luahblatex.fmt
LUALATEXFMT=$DIST/lualatex.fmt
BUSYTEX=$DIST/busytex

export TEXMFDIST=$DIST/texlive/texmf-dist
export TEXMFVAR=$DIST/texlive/texmf-dist/texmf-var
export TEXMFCNF=$TEXMFDIST/web2c
export FONTCONFIG_PATH=$DIST

cd example

$BUSYTEX xelatex --no-shell-escape --interaction nonstopmode --halt-on-error --no-pdf --fmt $XELATEXFMT example.tex
$BUSYTEX bibtex8 --8bit example.aux
$BUSYTEX xelatex --no-shell-escape --interaction nonstopmode --halt-on-error --no-pdf --fmt $XELATEXFMT example.tex
$BUSYTEX xelatex --no-shell-escape --interaction nonstopmode --halt-on-error --no-pdf --fmt $XELATEXFMT example.tex
$BUSYTEX xdvipdfmx -o example_xelatex.pdf example.xdv
rm example.aux

$BUSYTEX pdflatex --no-shell-escape --interaction nonstopmode --halt-on-error --output-format=pdf --fmt $PDFLATEXFMT example.tex
$BUSYTEX bibtex8 --8bit example.aux
$BUSYTEX pdflatex --no-shell-escape --interaction nonstopmode --halt-on-error --output-format=pdf --fmt $PDFLATEXFMT example.tex
$BUSYTEX pdflatex --no-shell-escape --interaction nonstopmode --halt-on-error --output-format=pdf --fmt $PDFLATEXFMT example.tex
mv example.pdf example_pdflatex.pdf
rm example.aux

$BUSYTEX luahblatex --no-shell-escape --interaction nonstopmode --halt-on-error --output-format=pdf --fmt $LUAHBLATEXFMT --nosocket example.tex 
$BUSYTEX bibtex8 --8bit example.aux
$BUSYTEX luahblatex --no-shell-escape --interaction nonstopmode --halt-on-error --output-format=pdf --fmt $LUAHBLATEXFMT --nosocket example.tex 
$BUSYTEX luahblatex --no-shell-escape --interaction nonstopmode --halt-on-error --output-format=pdf --fmt $LUAHBLATEXFMT --nosocket example.tex 
mv example.pdf example_luahblatex.pdf 
rm example.aux 

$BUSYTEX lualatex --no-shell-escape --interaction nonstopmode --halt-on-error --output-format=pdf --fmt $LUALATEXFMT --nosocket example.tex 
$BUSYTEX bibtex8 --8bit example.aux
$BUSYTEX lualatex --no-shell-escape --interaction nonstopmode --halt-on-error --output-format=pdf --fmt $LUALATEXFMT --nosocket example.tex 
$BUSYTEX lualatex --no-shell-escape --interaction nonstopmode --halt-on-error --output-format=pdf --fmt $LUALATEXFMT --nosocket example.tex 
mv example.pdf example_lualatex.pdf 
rm example.aux 
