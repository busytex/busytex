set -e

ENGINES="${@:-pdflatex xelatex luahbtex}"

export DIST=$PWD/dist-native
export BUSYTEX=$DIST/busytex

export TEXMFDIST=$DIST/texlive/texmf-dist
export TEXMFVAR=$DIST/texlive/texmf-dist/texmf-var
export TEXMFCNF=$DIST/texlive/texmf-dist/web2c
export FONTCONFIG_PATH=$DIST

export XELATEXFMT=$TEXMFVAR/xetex/xelatex.fmt
export PDFLATEXFMT=$TEXMFVAR/pdftex/pdflatex.fmt
export LUAHBLATEXFMT=$TEXMFVAR/luahbtex/luahblatex.fmt
export LUALATEXFMT=$TEXMFVAR/luahbtex/lualatex.fmt
	
if [ -d example ]; then
    cd example
fi

if [[ "$ENGINES" == *"pdflatex"* ]]; then
    $BUSYTEX pdflatex --no-shell-escape --interaction nonstopmode --halt-on-error --output-format=pdf --fmt $PDFLATEXFMT example.tex
    $BUSYTEX bibtex8 --8bit example.aux
    $BUSYTEX pdflatex --no-shell-escape --interaction nonstopmode --halt-on-error --output-format=pdf --fmt $PDFLATEXFMT example.tex
    $BUSYTEX pdflatex --no-shell-escape --interaction nonstopmode --halt-on-error --output-format=pdf --fmt $PDFLATEXFMT --jobname example_pdflatex.pdf example.tex
fi

if [[ "$ENGINES" == *"xelatex"* ]]; then
    $BUSYTEX xelatex --no-shell-escape --interaction nonstopmode --halt-on-error --no-pdf --fmt $XELATEXFMT example.tex
    $BUSYTEX bibtex8 --8bit example.aux
    $BUSYTEX xelatex --no-shell-escape --interaction nonstopmode --halt-on-error --no-pdf --fmt $XELATEXFMT example.tex
    $BUSYTEX xelatex --no-shell-escape --interaction nonstopmode --halt-on-error --no-pdf --fmt $XELATEXFMT example.tex
    $BUSYTEX xdvipdfmx -o example_xelatex.pdf example.xdv
fi

if [[ "$ENGINES" == *"luahblatex"* ]]; then
    $BUSYTEX luahblatex --no-shell-escape --interaction nonstopmode --halt-on-error --output-format=pdf --fmt $LUAHBLATEXFMT --nosocket example.tex
    $BUSYTEX bibtex8 --8bit example.aux
    $BUSYTEX luahblatex --no-shell-escape --interaction nonstopmode --halt-on-error --output-format=pdf --fmt $LUAHBLATEXFMT --nosocket example.tex
    $BUSYTEX luahblatex --no-shell-escape --interaction nonstopmode --halt-on-error --output-format=pdf --fmt $LUAHBLATEXFMT --jobname example_luahblatex.pdf --nosocket example.tex
fi
