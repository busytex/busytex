# based on:
# https://ctan.org/pkg/latexmk/
# https://www.cantab.net/users/johncollins/latexmk/
# https://mirrors.ctan.org/support/latexmk/latexmk.pl
# https://mg.readthedocs.io/latexmk.html
# https://github.com/schlamar/latexmk.py -> https://github.com/JanKanis/latexmk.py
# https://metacpan.org/release/TSCHWAND/TeX-AutoTeX-v0.906.0/view/lib/TeX/AutoTeX/File.pm
# https://github.com/Mrmaxmeier/tectonic-on-arXiv/blob/master/report.py


#build/native/fonts.conf:
#	mkdir -p $(dir $@)
#	echo '<?xml version="1.0"?>'                          > $@
#	echo '<!DOCTYPE fontconfig SYSTEM "fonts.dtd">'      >> $@
#	echo '<fontconfig>'                                  >> $@
#	#<dir prefix="relative">../texlive-basic/texmf-dist/fonts/opentype</dir>
#	#<dir prefix="relative">../texlive-basic/texmf-dist/fonts/type1</dir>
#	#<cachedir prefix="relative">./cache</cachedir>
#	echo '</fontconfig>'                                 >> $@

# https://www.freedesktop.org/software/fontconfig/fontconfig-user.html
# FC_DEVUG=MATCHV

#DIST=$PWD/dist-native
#XELATEXFMT=$DIST/xelatex.fmt
#PDFLATEXFMT=$DIST/pdflatex.fmt
#LUAHBLATEXFMT=$DIST/luahblatex.fmt
#LUALATEXFMT=$DIST/lualatex.fmt
#BUSYTEX=$DIST/busytex
#export TEXMFDIST=$DIST/texlive/texmf-dist
#export TEXMFVAR=$DIST/texlive/texmf-dist/texmf-var
#export TEXMFCNF=$TEXMFDIST/web2c
#export FONTCONFIG_PATH=$DIST
#cd example
#$BUSYTEX xelatex --no-shell-escape --interaction nonstopmode --halt-on-error --no-pdf --fmt $XELATEXFMT example.tex
#$BUSYTEX bibtex8 --8bit example.aux
#$BUSYTEX xelatex --no-shell-escape --interaction nonstopmode --halt-on-error --no-pdf --fmt $XELATEXFMT example.tex
#$BUSYTEX xelatex --no-shell-escape --interaction nonstopmode --halt-on-error --no-pdf --fmt $XELATEXFMT example.tex
#$BUSYTEX xdvipdfmx -o example_xelatex.pdf example.xdv
#rm example.aux
#$BUSYTEX pdflatex --no-shell-escape --interaction nonstopmode --halt-on-error --output-format=pdf --fmt $PDFLATEXFMT example.tex
#$BUSYTEX bibtex8 --8bit example.aux
#$BUSYTEX pdflatex --no-shell-escape --interaction nonstopmode --halt-on-error --output-format=pdf --fmt $PDFLATEXFMT example.tex
#$BUSYTEX pdflatex --no-shell-escape --interaction nonstopmode --halt-on-error --output-format=pdf --fmt $PDFLATEXFMT example.tex
#mv example.pdf example_pdflatex.pdf
#rm example.aux

#class BusytexBibtexResolver
#{
#    resolve (files, bib_tex_commands = ['\\bibliography', '\\printbibliography'])
#    {
#        return files.some(f => f.path.endsWith('.tex') && typeof(f.contents) == 'string' && bib_tex_commands.some(b => f.contents.includes(b)));
#        // files.some(({path, contents}) => contents != null && path.endsWith('.bib'));
#    }
#}
# this.verbose_args = 
#        {
#            [BusytexPipeline.VerboseInfo] : {
#                pdftex    : ['-kpathsea-debug', '32'],
#                xetex     : ['-kpathsea-debug', '32'],
#                luatex  : ['-kpathsea-debug', '32'],
#                luahbtex  : ['-kpathsea-debug', '32'],
#                xdvipdfmx : ['--kpathsea-debug','32', '-v'],
#                bibtex8   : ['--debug', 'search'],
#            },
#            [BusytexPipeline.VerboseDebug] : {
#                pdftex    : ['-kpathsea-debug', '63', '-recorder'],
#                xetex     : ['-kpathsea-debug', '63', '-recorder'],
#                luatex  : ['-kpathsea-debug', '63', '-recorder', '--debug-format'],
#                luahbtex  : ['-kpathsea-debug', '63', '-recorder', '--debug-format'],
#                xdvipdfmx : ['--kpathsea-debug','63', '-vv'],
#                bibtex8   : ['--debug', 'all'],
#            },
#        };
#this.error_messages_fatal = ['Fatal error occurred', 'That was a fatal error', ':fatal:', '! Undefined control sequence.', 'undefined old font command'];
#this.error_messages_all = this.error_messages_fatal.concat(['no output PDF file produced', 'No pages of output.']);
#this.env = {TEXMFDIST       : this.dir_texmfdist, TEXMFVAR        : this.dir_texmfvar, TEXMFCNF        : this.dir_cnf, TEXMFLOG        : this.texmflog, FONTCONFIG_PATH : this.dir_fontconfig};
#this.dir_texmfdist = [...BusytexPipeline.texmf_system, ...texmf_local].map(texmf => texmf + '/texmf-dist').join(':');
#        this.dir_texmfvar = '/texlive/texmf-dist/texmf-var';
#        this.dir_cnf = '/texlive/texmf-dist/web2c';
#        this.dir_fontconfig = '/etc/fonts';
#        this.texmflog = '/tmp/texmf.log';
#        this.missfontlog = 'missfont.log'; // http://tug.ctan.org/info/tex-font-errors-cheatsheet/tex-font-cheatsheet.pdf 
#const is_bibtex = cmd[0].startsWith('bibtex');
#            const cmd_log_path = is_bibtex ? blg_path : log_path;
#            const cmd_aux_path = is_bibtex ? bbl_path : aux_path;
#TAGS = {
#    # TODO: this is output from xdvipdfmx
#    'no-font-for-pdf': "Cannot proceed without .vf or \"physical\" font for PDF output...",
#    'latex-pstricks-not-found': "! LaTeX Error: File `pstricks.sty' not found.",
#    'latex-file-not-found': "LaTeX Error: File",
#    'undefined-control-sequence': "! Undefined control sequence.",
#    'not-latex': "LaTeX Error: Missing \\begin{document}",
#    'uses-inputenc': "Package inputenc Error: inputenc is not designed for xetex or luatex.",
#    'latex-error': "LaTeX Error",
#    'bad-character-code': "! Bad character code",
#    'bib-failed': "\\end{thebibliography}"
#}

#xdvipdfmx:warning: Color stack underflow. Just ignore.
#xdvipdfmx:warning: Color stack underflow. Just ignore.
#xdvipdfmx:warning: Color stack underflow. Just ignore.
#xdvipdfmx:warning: Color stack underflow. Just ignore.
#xdvipdfmx:warning: Color stack underflow. Just ignore.

#kpathsea: Running mktexpk --mfmode / --bdpi 600 --mag 1+264/600 --dpi 864 ec-qhvr
#kpathsea: fork(): Function not implemented
#kpathsea: Appending font creation commands to missfont.log.
#xdvipdfmx:warning: Could not locate a virtual/physical font for TFM "ec-qhvr".
#xdvipdfmx:warning: >> There are no valid font mapping entry for this font.
#xdvipdfmx:warning: >> Font file name "ec-qhvr" was assumed but failed to locate that font.
#xdvipdfmx:fatal: Cannot proceed without .vf or "physical" font for PDF output...
#No output PDF file written.

# return *.synctex.gz https://tex.stackexchange.com/a/118491/115598


import argparse
import subprocess

def xelatex():
    pass

def pdflatex():
    pass

def main(args):
    pass

if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--input-path', '-i')
    parser.add_argument('--driver', default = 'xelatex', choices = ['xelatex', 'pdflatex'])
    parser.add_argument('--busytex', default = 'build/native/busytex')
    args = parser.parse_args()
    main(args)
