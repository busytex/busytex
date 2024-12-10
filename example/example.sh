set -e

ENGINES="${@:-busytex pdflatex xelatex luahbtex}"

if [[ "$ENGINES" == *"busytexbasic"* ]]; then
    export BUSYTEX=busytexbasic
    export TEXMFVAR=/texlive/texmf-dist/texmf-var
    export FONTCONFIG_PATH=$PWD
else
    export BUSYTEX=busytex

    export TEXMFLOG=/tmp/texmf.log
    export TEXMFDIST=$(dirname $(which $BUSYTEX))/texlive/texmf-dist
    export TEXMFCNF=$( dirname $(which $BUSYTEX))/texlive/texmf-dist/web2c
    export TEXMFVAR=$( dirname $(which $BUSYTEX))/texlive/texmf-dist/texmf-var

    export FONTCONFIG_PATH=$DIST
fi

if [ -d example ]; then
    cd example
fi

if [[ "$ENGINES" == *"pdflatex"* ]]; then
    $BUSYTEX pdflatex --no-shell-escape --interaction nonstopmode --halt-on-error --output-format=pdf --fmt $TEXMFVAR/web2c/pdftex/pdflatex.fmt example.tex
    $BUSYTEX bibtex8 --8bit example.aux
    $BUSYTEX pdflatex --no-shell-escape --interaction nonstopmode --halt-on-error --output-format=pdf --fmt $TEXMFVAR/web2c/pdftex/pdflatex.fmt example.tex
    $BUSYTEX pdflatex --no-shell-escape --interaction nonstopmode --halt-on-error --output-format=pdf --fmt $TEXMFVAR/web2c/pdftex/pdflatex.fmt --jobname example_pdflatex.pdf example.tex
fi

if [[ "$ENGINES" == *"xelatex"* ]]; then
    $BUSYTEX xelatex --no-shell-escape --interaction nonstopmode --halt-on-error --no-pdf --fmt $TEXMFVAR/web2c/xetex/xelatex.fmt example.tex
    $BUSYTEX bibtex8 --8bit example.aux
    $BUSYTEX xelatex --no-shell-escape --interaction nonstopmode --halt-on-error --no-pdf --fmt $TEXMFVAR/web2c/xetex/xelatex.fmt example.tex
    $BUSYTEX xelatex --no-shell-escape --interaction nonstopmode --halt-on-error --no-pdf --fmt $TEXMFVAR/web2c/xetex/xelatex.fmt example.tex
    $BUSYTEX xdvipdfmx -o example_xelatex.pdf example.xdv
fi

if [[ "$ENGINES" == *"luahblatex"* ]]; then
    $BUSYTEX luahblatex --no-shell-escape --interaction nonstopmode --halt-on-error --output-format=pdf --fmt $TEXMVAR/web2c/luahbtex/luahblatex.fmt --nosocket example.tex
    $BUSYTEX bibtex8 --8bit example.aux
    $BUSYTEX luahblatex --no-shell-escape --interaction nonstopmode --halt-on-error --output-format=pdf --fmt $TEXMVAR/web2c/luahbtex/luahblatex.fmt --nosocket example.tex
    $BUSYTEX luahblatex --no-shell-escape --interaction nonstopmode --halt-on-error --output-format=pdf --fmt $TEXMVAR/web2c/luahbtex/luahblatex.fmt --jobname example_luahblatex.pdf --nosocket example.tex
fi
