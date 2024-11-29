set -e

export DIST=$PWD/dist-native
export TEXMFDIST=$DIST/texlive/texmf-dist
export TEXMFVAR=$DIST/texlive/texmf-dist/texmf-var
export TEXMFCNF=$TEXMFDIST/web2c
export FONTCONFIG_PATH=$DIST

export XELATEXFMT=$DIST/xelatex.fmt
export PDFLATEXFMT=$DIST/pdflatex.fmt
export LUAHBLATEXFMT=$DIST/luahblatex.fmt
export LUALATEXFMT=$DIST/lualatex.fmt
export BUSYTEX=$DIST/busytex

ENGINES="${@:-pdflatex xelatex luahbtex}"

cd example

if [[ "$engines" == *"pdflatex"* ]]; then
    $BUSYTEX pdflatex --no-shell-escape --interaction nonstopmode --halt-on-error --output-format=pdf --fmt $PDFLATEXFMT example.tex
    $BUSYTEX bibtex8 --8bit example.aux
    $BUSYTEX pdflatex --no-shell-escape --interaction nonstopmode --halt-on-error --output-format=pdf --fmt $PDFLATEXFMT example.tex
    $BUSYTEX pdflatex --no-shell-escape --interaction nonstopmode --halt-on-error --output-format=pdf --fmt $PDFLATEXFMT example.tex
    mv example.pdf example_pdflatex.pdf
    rm example.aux
fi

if [[ "$engines" == *"xelatex"* ]]; then
    $BUSYTEX xelatex --no-shell-escape --interaction nonstopmode --halt-on-error --no-pdf --fmt $XELATEXFMT example.tex
    $BUSYTEX bibtex8 --8bit example.aux
    $BUSYTEX xelatex --no-shell-escape --interaction nonstopmode --halt-on-error --no-pdf --fmt $XELATEXFMT example.tex
    $BUSYTEX xelatex --no-shell-escape --interaction nonstopmode --halt-on-error --no-pdf --fmt $XELATEXFMT example.tex
    $BUSYTEX xdvipdfmx -o example_xelatex.pdf example.xdv
    rm example.aux
fi

if [[ "$engines" == *"luahblatex"* ]]; then
    $BUSYTEX luahblatex --no-shell-escape --interaction nonstopmode --halt-on-error --output-format=pdf --fmt $LUAHBLATEXFMT --nosocket example.tex
    $BUSYTEX bibtex8 --8bit example.aux
    $BUSYTEX luahblatex --no-shell-escape --interaction nonstopmode --halt-on-error --output-format=pdf --fmt $LUAHBLATEXFMT --nosocket example.tex
    $BUSYTEX luahblatex --no-shell-escape --interaction nonstopmode --halt-on-error --output-format=pdf --fmt $LUAHBLATEXFMT --nosocket example.tex
    mv example.pdf example_luahblatex.pdf
    rm example.aux
fi
