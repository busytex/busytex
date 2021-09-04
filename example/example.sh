set -e

export DIST=$PWD/dist-native
export XETEXFMT=$DIST/xelatex.fmt
export PDFTEXFMT=$DIST/pdflatex.fmt
export LUATEXFMT=$DIST/lualatex.fmt
export BUSYTEX=$DIST/busytex

export TEXMFDIST=$DIST/texlive/texmf-dist
export TEXMFVAR=$DIST/texlive/texmf-dist/texmf-var
export TEXMFCNF=$TEXMFDIST/web2c
export FONTCONFIG_PATH=$DIST

cd example

$BUSYTEX

for applet in $($BUSYTEX); do
    echo $BUSYTEX $applet --version
    $BUSYTEX $applet --version
done

$BUSYTEX xetex --version
$BUSYTEX xetex --no-shell-escape --interaction nonstopmode --halt-on-error --no-pdf --fmt $XETEXFMT example.tex
$BUSYTEX bibtex8 --8bit example.aux
$BUSYTEX xetex --no-shell-escape --interaction nonstopmode --halt-on-error --no-pdf --fmt $XETEXFMT example.tex
$BUSYTEX xetex --no-shell-escape --interaction nonstopmode --halt-on-error --no-pdf --fmt $XETEXFMT example.tex
$BUSYTEX xdvipdfmx -o example_xetex.pdf example.xdv
rm example.aux

$BUSYTEX pdftex --version
$BUSYTEX pdftex --no-shell-escape --interaction nonstopmode --halt-on-error --output-format=pdf --fmt $PDFTEXFMT example.tex
$BUSYTEX bibtex8 --8bit example.aux
$BUSYTEX pdftex --no-shell-escape --interaction nonstopmode --halt-on-error --output-format=pdf --fmt $PDFTEXFMT example.tex
$BUSYTEX pdftex --no-shell-escape --interaction nonstopmode --halt-on-error --output-format=pdf --fmt $PDFTEXFMT example.tex
mv example.pdf example_pdftex.pdf
rm example.aux

#$BUSYLUATEX luatex --no-shell-escape --interaction nonstopmode --halt-on-error --output-format=pdf --fmt $LUATEXFMT example.tex
#$BUSYLUATEX bibtex8 --8bit example.aux                                           
#$BUSYLUATEX luatex --no-shell-escape --interaction nonstopmode --halt-on-error --output-format=pdf --fmt $LUATEXFMT example.tex
#$BUSYLUATEX luatex --no-shell-escape --interaction nonstopmode --halt-on-error --output-format=pdf --fmt $LUATEXFMT example.tex
#mv example.pdf example_luatex.pdf
#rm example.aux
