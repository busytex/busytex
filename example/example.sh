set -e

export BUSYTEX=$(which $1)
export ENGINES="${@:-pdflatex xelatex luahbtex}"

export TEXMFLOG=$PWD/texmf.log
# export TEXINPUTS=.:./example/

if [[ "$1" == "busytex" ]]; then
    export DIST=$(dirname $BUSYTEX)
    export TEXMFDIST=$DIST/texlive-dist/texmf-dist
    export  TEXMFCNF=$DIST/texlive-dist/texmf-dist/web2c
    export  TEXMFVAR=$DIST/texlive-dist/texmf-dist/texmf-var
    export FONTCONFIG_PATH=$DIST/texlive-dist
fi

if [ -d example ]; then
    cd example
fi

if [[ "$ENGINES" == *"pdflatex"* ]]; then
    #--fmt $TEXMFVAR/web2c/pdftex/pdflatex.fmt 
    $BUSYTEX pdflatex --no-shell-escape --interaction nonstopmode --draftmode --halt-on-error --output-format=pdf --progname pdflatex example.tex
    $BUSYTEX bibtex8 --8bit example.aux
    $BUSYTEX pdflatex --no-shell-escape --interaction nonstopmode --draftmode --halt-on-error --output-format=pdf --progname pdflatex example.tex
    $BUSYTEX pdflatex --no-shell-escape --interaction nonstopmode --halt-on-error --output-format=pdf --progname pdflatex --jobname example_pdflatex.pdf example.tex
fi
if [[ "$ENGINES" == *"xelatex"* ]]; then
    # --fmt $TEXMFVAR/web2c/xetex/xelatex.fmt
    $BUSYTEX xelatex --no-shell-escape --interaction nonstopmode --halt-on-error --no-pdf --progname xelatex  example.tex
    $BUSYTEX bibtex8 --8bit example.aux
    $BUSYTEX xelatex --no-shell-escape --interaction nonstopmode --halt-on-error --no-pdf --progname xelatex example.tex
    $BUSYTEX xelatex --no-shell-escape --interaction nonstopmode --halt-on-error --no-pdf --progname xelatex example.tex
    $BUSYTEX xdvipdfmx -o example_xelatex.pdf example.xdv
fi
if [[ "$ENGINES" == *"luahblatex"* ]]; then
    # --fmt $TEXMVAR/web2c/luahbtex/luahblatex.fmt
    $BUSYTEX luahblatex --no-shell-escape --interaction nonstopmode --draftmode --halt-on-error --output-format=pdf --progname luahblatex  --nosocket example.tex
    $BUSYTEX bibtex8 --8bit example.aux
    $BUSYTEX luahblatex --no-shell-escape --interaction nonstopmode --draftmode --halt-on-error --output-format=pdf --progname luahblatex --nosocket example.tex
    $BUSYTEX luahblatex --no-shell-escape --interaction nonstopmode --halt-on-error --output-format=pdf --progname luahblatex --jobname example_luahblatex.pdf --nosocket example.tex
fi
