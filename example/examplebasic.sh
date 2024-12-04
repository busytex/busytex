set -e

export BUSYTEX=$PWD/build/native/busytexbasic

export PDFLATEXFMT=/texlive/texmf-dist/texmf-var/web2c/pdftex/pdflatex.fmt
        
export TEXMFDIST=/texlive/texmf-dist
export TEXMFVAR=/texlive/texmf-dist/texmf-var
export TEXMFCNF=/texlive/texmf-dist/web2c
export TEXMFLOG=/tmp/texmf.log
export FONTCONFIG_PATH=$PWD/dist-native
#/etc/fonts

cd example

$BUSYTEX pdflatex --no-shell-escape --interaction nonstopmode --halt-on-error --output-format=pdf --fmt $PDFLATEXFMT example.tex
$BUSYTEX bibtex8 --8bit example.aux
$BUSYTEX pdflatex --no-shell-escape --interaction nonstopmode --halt-on-error --output-format=pdf --fmt $PDFLATEXFMT example.tex
$BUSYTEX pdflatex --no-shell-escape --interaction nonstopmode --halt-on-error --output-format=pdf --fmt $PDFLATEXFMT example.tex
mv example.pdf example_pdflatex.pdf
rm example.aux
