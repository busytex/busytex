set -e

export BUSYTEX=$PWD/build/native/busytexbasic

export PDFLATEXFMT=/texlive/texmf-dist/texmf-var/web2c/pdftex/pdflatex.fmt
        
export TEXMFDIST=/texlive/texmf-dist
export TEXMFVAR=/texlive/texmf-dist/texmf-var
export TEXMFCNF=/texlive/texmf-dist/web2c
export TEXMFLOG=/tmp/texmf.log
export FONTCONFIG_PATH=$PWD

cd example

echo 000
$BUSYTEX pdflatex  --version
$BUSYTEX bibtex8   --version
$BUSYTEX kpsewhich --version
echo 111
$BUSYTEX pdflatex --no-shell-escape --interaction nonstopmode --halt-on-error --output-format=pdf --fmt $PDFLATEXFMT example.tex
echo 222
$BUSYTEX bibtex8 --8bit example.aux
echo 333
$BUSYTEX pdflatex --no-shell-escape --interaction nonstopmode --halt-on-error --output-format=pdf --fmt $PDFLATEXFMT example.tex
echo 444
$BUSYTEX pdflatex --no-shell-escape --interaction nonstopmode --halt-on-error --output-format=pdf --fmt $PDFLATEXFMT example.tex
mv example.pdf example_pdflatex.pdf
rm example.aux
