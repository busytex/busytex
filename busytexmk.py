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

#class BusytexBibtexResolver
#{
#    resolve (files, bib_tex_commands = ['\\bibliography', '\\printbibliography'])
#    {
#        return files.some(f => f.path.endsWith('.tex') && typeof(f.contents) == 'string' && bib_tex_commands.some(b => f.contents.includes(b)));
#        // files.some(({path, contents}) => contents != null && path.endsWith('.bib'));
#    }
#}
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

#kpathsea: Running mktexpk --mfmode / --bdpi 600 --mag 1+264/600 --dpi 864 ec-qhvr
#kpathsea: fork(): Function not implemented
#kpathsea: Appending font creation commands to missfont.log.

# return *.synctex.gz https://tex.stackexchange.com/a/118491/115598


import argparse
import subprocess

def xelatex(main_tex_path, busytex):
#DIST=$PWD/dist-native
#XELATEXFMT=$DIST/xelatex.fmt
#BUSYTEX=$DIST/busytex
#export TEXMFDIST=$DIST/texlive/texmf-dist
#export TEXMFVAR=$DIST/texlive/texmf-dist/texmf-var
#export TEXMFCNF=$TEXMFDIST/web2c
#export FONTCONFIG_PATH=$DIST
#xdvipdfmx:warning: Could not locate a virtual/physical font for TFM "ec-qhvr".
#xdvipdfmx:warning: >> There are no valid font mapping entry for this font.
#xdvipdfmx:warning: >> Font file name "ec-qhvr" was assumed but failed to locate that font.
#xdvipdfmx:fatal: Cannot proceed without .vf or "physical" font for PDF output...
#No output PDF file written.
#xdvipdfmx:warning: Color stack underflow. Just ignore.
#xdvipdfmx:warning: Color stack underflow. Just ignore.
#xdvipdfmx:warning: Color stack underflow. Just ignore.
#xdvipdfmx:warning: Color stack underflow. Just ignore.
#xdvipdfmx:warning: Color stack underflow. Just ignore.
#xdvipdfmx:warning: Could not locate a virtual/physical font for TFM "ec-qhvr".
#xdvipdfmx:warning: >> There are no valid font mapping entry for this font.
#xdvipdfmx:warning: >> Font file name "ec-qhvr" was assumed but failed to locate that font.
#xdvipdfmx:fatal: Cannot proceed without .vf or "physical" font for PDF output...
# this.verbose_args = 
#        {
#            [BusytexPipeline.VerboseInfo] : {
#                xetex     : ['-kpathsea-debug', '32'],
#                xdvipdfmx : ['--kpathsea-debug','32', '-v'],
#                bibtex8   : ['--debug', 'search'],
#            },
#            [BusytexPipeline.VerboseDebug] : {
#                xetex     : ['-kpathsea-debug', '63', '-recorder'],
#                xdvipdfmx : ['--kpathsea-debug','63', '-vv'],
#                bibtex8   : ['--debug', 'all'],
#            },
#        };
#$BUSYTEX xelatex --no-shell-escape --interaction nonstopmode --halt-on-error --no-pdf --fmt $XELATEXFMT example.tex
#$BUSYTEX bibtex8 --8bit example.aux
#$BUSYTEX xelatex --no-shell-escape --interaction nonstopmode --halt-on-error --no-pdf --fmt $XELATEXFMT example.tex
#$BUSYTEX xelatex --no-shell-escape --interaction nonstopmode --halt-on-error --no-pdf --fmt $XELATEXFMT example.tex
#$BUSYTEX xdvipdfmx -o example_xelatex.pdf example.xdv
#rm example.aux
    pass

def pdflatex(main_tex_path, busytex):
#DIST=$PWD/dist-native
#PDFLATEXFMT=$DIST/pdflatex.fmt
#BUSYTEX=$DIST/busytex
#export TEXMFDIST=$DIST/texlive/texmf-dist
#export TEXMFVAR=$DIST/texlive/texmf-dist/texmf-var
#export TEXMFCNF=$TEXMFDIST/web2c
#export FONTCONFIG_PATH=$DIST
# this.verbose_args = 
#        {
#            [BusytexPipeline.VerboseInfo] : {
#                pdftex    : ['-kpathsea-debug', '32'],
#                bibtex8   : ['--debug', 'search'],
#            },
#            [BusytexPipeline.VerboseDebug] : {
#                pdftex    : ['-kpathsea-debug', '63', '-recorder'],
#                bibtex8   : ['--debug', 'all'],
#            },
#        };
    subprocess.run([busytex, 'pdflatex', '--no-shell-escape', '--interaction=nonstopmode', '--halt-on-error', '--output-format=pdf', '--fmt', PDFLATEXFMT, main_tex_path])
    subprocess.run([busytex, 'bibtex8', '--8bit', main_tex_path.removesuffix('.tex') + '.aux'])
    subprocess.run([busytex, 'pdflatex', '--no-shell-escape', '--interaction=nonstopmode', '--halt-on-error', '--output-format=pdf', '--fmt', PDFLATEXFMT, main_tex_path])
    subprocess.run([busytex, 'pdflatex', '--no-shell-escape', '--interaction=nonstopmode', '--halt-on-error', '--output-format=pdf', '--fmt', PDFLATEXFMT, main_tex_path])
    #mv example.pdf  example.aux
#     const tex_path = PATH.basename(main_tex_path), dirname = PATH.dirname(main_tex_path);
#
#        const [xdv_path, pdf_path, log_path, aux_path, blg_path, bbl_path] = ['.xdv', '.pdf', '.log', '.aux', '.blg', '.bbl'].map(ext => tex_path.replace('.tex', ext));
#
#        const xetex     = ['xelatex' ,   '--no-shell-escape', '--interaction=batchmode', '--halt-on-error', '--no-pdf'           , '--fmt', this.fmt.xetex , tex_path].concat((this.verbose_args[verbose] || this.verbose_args[BusytexPipeline.VerboseSilent]).xetex);
#        const pdftex    = ['pdflatex',   '--no-shell-escape', '--interaction=nonstopmode', '--halt-on-error', '--output-format=pdf', '--fmt', this.fmt.pdftex, tex_path].concat((this.verbose_args[verbose] || this.verbose_args[BusytexPipeline.VerboseSilent]).pdftex);
#        const pdftex_not_final    = ['pdflatex',   '--no-shell-escape', '--interaction=batchmode', '--halt-on-error', '--fmt', this.fmt.pdftex, tex_path].concat((this.verbose_args[verbose] || this.verbose_args[BusytexPipeline.VerboseSilent]).pdftex);
#
#        const luahbtex  = ['luahblatex', '--no-shell-escape', '--interaction=nonstopmode', '--halt-on-error', '--output-format=pdf', '--fmt', this.fmt.luahbtex, '--nosocket', tex_path].concat((this.verbose_args[verbose] || this.verbose_args[BusytexPipeline.VerboseSilent]).luahbtex);
#        const luahbtex_not_final  = ['luahblatex', '--no-shell-escape', '--interaction=nonstopmode', '--halt-on-error', '--no-pdf', '--fmt', this.fmt.luahbtex, '--nosocket', tex_path].concat((this.verbose_args[verbose] || this.verbose_args[BusytexPipeline.VerboseSilent]).luahbtex);
#
#        const luatex  = ['lualatex', '--no-shell-escape', '--interaction=nonstopmode', '--halt-on-error', '--output-format=pdf', '--fmt', this.fmt.luatex, '--nosocket', tex_path].concat((this.verbose_args[verbose] || this.verbose_args[BusytexPipeline.VerboseSilent]).luahbtex);
#        const luatex_not_final  = ['lualatex', '--no-shell-escape', '--interaction=nonstopmode', '--halt-on-error', '--no-pdf', '--fmt', this.fmt.luatex, '--nosocket', tex_path].concat((this.verbose_args[verbose] || this.verbose_args[BusytexPipeline.VerboseSilent]).luahbtex);
#
#        const bibtex8   = ['bibtex8', '--8bit', aux_path].concat((this.verbose_args[verbose] || this.verbose_args[BusytexPipeline.VerboseSilent]).bibtex8);
#
#        const xdvipdfmx = ['xdvipdfmx', '-o', pdf_path, xdv_path].concat((this.verbose_args[verbose] || this.verbose_args[BusytexPipeline.VerboseSilent]).xdvipdfmx);
#  const logcat = logs.map(({cmd, texmflog, missfontlog, log, exit_code, stdout, stderr}) => ([`$ ${cmd}`, `EXITCODE: ${exit_code}`, '', 'TEXMFLOG:', texmflog, '==', 'MISSFONTLOG:', missfontlog, '==', 'LOG:', log, '==', 'STDOUT:', stdout, '==', 'STDERR:', stderr, '======'].join('\n'))).join('\n\n');
#  logs.push({
#                cmd : cmd.join(' '),
#                texmflog    : (verbose == BusytexPipeline.VerboseInfo || verbose == BusytexPipeline.VerboseDebug) ? this.read_all_text(FS, this.texmflog) : '',
#                missfontlog : (verbose == BusytexPipeline.VerboseInfo || verbose == BusytexPipeline.VerboseDebug) ? this.read_all_text(FS, this.missfontlog) : '',
#                log : log.trim(),
#                aux : aux.trim(),
#                stdout : stdout.trim(),
#                stderr : stderr.trim(),
#                exit_code : exit_code
#            });
#             cmds = bibtex ?
#                [
#                    [pdftex_not_final, this.error_messages_fatal, false],
#                    [bibtex8, this.error_messages_fatal, true],
#                    [pdftex_not_final, this.error_messages_fatal, true],
#                    [pdftex, this.error_messages_all, false]
#                ] :
#                [
#                    [pdftex, this.error_messages_all]
#                ];



def detect_main_tex_path(dirname):
    #const basename = this.PATH.basename(dirname);
    #const tex_files = this.find(dirname, '', false).filter(f => f.contents != null && f.path.endsWith(this.tex_ext));
    #let default_path = null;
    #
    #if(tex_files.length == 1)
    #    default_path = tex_files[0].path;

    #else if(tex_files.length > 1)
    #{
    #    const main_tex_files = this.find(dirname, '', false).filter(f => f.contents != null && f.path.endsWith(this.tex_ext) && (f.path.includes('main') || f.path.includes(basename)));
    #    default_path = main_tex_files.length > 0 ? main_tex_files[0].path : tex_files[0].path;
    #}

    #if(default_path == null)
    #{
    #    const text_files = this.find(dirname, '', false).filter(f => f.contents != null && this.text_extensions.some(ext => f.path.toLowerCase().endsWith(ext)));
    #    if(text_files.length == 1)
    #        default_path = text_files[0].path;
    #    else if(text_files.length > 1)
    #    {
    #        const main_text_files = this.find(dirname, '', false).filter(f => f.contents != null && f.path.toUpperCase().includes('README'));
    #        default_path = main_text_files.length > 0 ? main_text_files[0].path : text_files[0].path;
    #    }
    #}
    default_path = None
    return default_path

def main(args):
    main_tex_path = detect_main_tex_path(args.input_path)

    if args.driver == 'pdflatex':
        pdflatex(main_tex_path, args.busytex)
    
    if args.driver == 'xelatex':
        xelatex(main_tex_path, args.busytex)


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--input-path', '-i', required = True)
    parser.add_argument('--driver', default = 'xelatex', choices = ['xelatex', 'pdflatex'])
    parser.add_argument('--busytex', default = 'build/native/busytex')
    args = parser.parse_args()
    main(args)
