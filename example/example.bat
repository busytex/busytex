@echo off
set DIST=%cd%\dist-native
set XELATEXFMT=%DIST%\xelatex.fmt
set PDFLATEXFMT=%DIST%\pdflatex.fmt
set LUAHBLATEXFMT=%DIST%\luahblatex.fmt
set LUALATEXFMT=%DIST%\lualatex.fmt
set BUSYTEX=%DIST%\busytex.com

set TEXMFDIST=%DIST%\texlive\texmf-dist
set TEXMFVAR=%DIST%\texlive\texmf-dist\texmf-var
set TEXMFCNF=%TEXMFDIST%\web2c
set FONTCONFIG_PATH=%DIST%

cd example

%BUSYTEX% xelatex --no-shell-escape --interaction nonstopmode --halt-on-error --no-pdf --fmt %XELATEXFMT% example.tex
%BUSYTEX% bibtex8 --8bit example.aux
%BUSYTEX% xelatex --no-shell-escape --interaction nonstopmode --halt-on-error --no-pdf --fmt %XELATEXFMT% example.tex
%BUSYTEX% xelatex --no-shell-escape --interaction nonstopmode --halt-on-error --no-pdf --fmt %XELATEXFMT% example.tex
%BUSYTEX% xdvipdfmx -o example_xelatex.pdf example.xdv
erase example.aux

%BUSYTEX% pdflatex --no-shell-escape --interaction nonstopmode --halt-on-error --output-format=pdf --fmt %PDFLATEXFMT% example.tex
%BUSYTEX% bibtex8 --8bit example.aux
%BUSYTEX% pdflatex --no-shell-escape --interaction nonstopmode --halt-on-error --output-format=pdf --fmt %PDFLATEXFMT% example.tex
%BUSYTEX% pdflatex --no-shell-escape --interaction nonstopmode --halt-on-error --output-format=pdf --fmt %PDFLATEXFMT% example.tex
move example.pdf example_pdflatex.pdf
erase example.aux

%BUSYTEX% luahblatex --no-shell-escape --interaction nonstopmode --halt-on-error --output-format=pdf --fmt %LUAHBLATEXFMT% --nosocket example.tex
%BUSYTEX% bibtex8 --8bit example.aux
%BUSYTEX% luahblatex --no-shell-escape --interaction nonstopmode --halt-on-error --output-format=pdf --fmt %LUAHBLATEXFMT% --nosocket example.tex
%BUSYTEX% luahblatex --no-shell-escape --interaction nonstopmode --halt-on-error --output-format=pdf --fmt %LUAHBLATEXFMT% --nosocket example.tex
move example.pdf example_luahblatex.pdf
erase example.aux
