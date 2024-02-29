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


#kpathsea: Running mktexpk --mfmode / --bdpi 600 --mag 1+264/600 --dpi 864 ec-qhvr
#kpathsea: fork(): Function not implemented
#kpathsea: Appending font creation commands to missfont.log.

# return *.synctex.gz https://tex.stackexchange.com/a/118491/115598


import os
import argparse
import subprocess

def read_all_text(path, encoding = 'utf-8', errors = 'replace'):
    with open(path, 'r', encoding = encoding, errors = errors) as f:
        return f.read()

def read_all_bytes(path):
    with open(path, 'rb') as f:
        return f.read()

def xelatex():
    xetex     = ['xelatex' ,   '--no-shell-escape', '--interaction=batchmode', '--halt-on-error', '--no-pdf'           , '--fmt', this.fmt.xetex , tex_path]
    xdvipdfmx = ['xdvipdfmx', '-o', pdf_path, xdv_path]
    arg_xetex_debug = ['-kpathsea-debug', '63', '-recorder']
    arg_xetex_verbose = ['-kpathsea-debug', '32']
    arg_xdvipdfmx_verbose = ['--kpathsea-debug','32', '-v']
    arg_xdvipdfmx_debug = ['--kpathsea-debug','63', '-vv']
    FMT = os.path.join(DIST, 'xelatex.fmt')
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
    #$BUSYTEX xelatex --no-shell-escape --interaction nonstopmode --halt-on-error --no-pdf --fmt $XELATEXFMT example.tex
    #$BUSYTEX bibtex8 --8bit example.aux
    #$BUSYTEX xelatex --no-shell-escape --interaction nonstopmode --halt-on-error --no-pdf --fmt $XELATEXFMT example.tex
    #$BUSYTEX xelatex --no-shell-escape --interaction nonstopmode --halt-on-error --no-pdf --fmt $XELATEXFMT example.tex
    #$BUSYTEX xdvipdfmx -o example_xelatex.pdf example.xdv
    pass

def pdflatex(tex_relative_path, busytex, cwd, DIST, bibtex):
# http://tug.ctan.org/info/tex-font-errors-cheatsheet/tex-font-cheatsheet.pdf 
# https://www.freedesktop.org/software/fontconfig/fontconfig-user.html
#         Name         Value    Meaning
#         ---------------------------------------------------------
#         MATCH            1    Brief information about font matching
#         MATCHV           2    Extensive font matching information
#         EDIT             4    Monitor match/test/edit execution
#         FONTSET          8    Track loading of font information at startup
#         CACHE           16    Watch cache files being written
#         CACHEV          32    Extensive cache file writing information
#         PARSE           64    (no longer in use)
#         SCAN           128    Watch font files being scanned to build caches
#         SCANV          256    Verbose font file scanning information
#         MEMORY         512    Monitor fontconfig memory usage
#         CONFIG        1024    Monitor which config files are loaded
#         LANGSET       2048    Dump char sets used to construct lang values
#         OBJTYPES      4096    Display message when value typechecks fail

    env = dict(
        TEXMFDIST = os.path.join(DIST, 'texlive/texmf-dist'),
        TEXMFVAR  = os.path.join(DIST, 'texlive/texmf-dist/texmf-var'),
        TEXMFCNF  = os.path.join(DIST, 'texlive/texmf-dist/web2c'),
        FONTCONFIG_PATH = DIST,
        FC_DEBUG = 'SCANV'
    )
    fmt = os.path.join(DIST, 'pdflatex.fmt')
    texmflog = 'texmf.log'
    missfontlog = 'missfont.log'
    
    error_messages_fatal = ['Fatal error occurred', 'That was a fatal error', ':fatal:', '! Undefined control sequence.', '! Bad character code', 'undefined old font command', 'LaTeX Error', 'Cannot proceed without .vf or \"physical\" font for PDF output...', 'LaTeX Error: File', 'Package inputenc Error: inputenc is not designed for xetex or luatex.', 'LaTeX Error: Missing \\begin{document}', '\\end{thebibliography}']
    error_messages_all = error_messages_fatal + ['no output PDF file produced', 'No pages of output.']
    has_error = lambda cmdres, errors: any(e.encode() in cmdres.stdout + cmdres.stderr for e in errors)

    # env = {TEXMFDIST : this.dir_texmfdist, TEXMFVAR : this.dir_texmfvar, TEXMFCNF : this.dir_cnf, TEXMFLOG : this.texmflog, FONTCONFIG_PATH : this.dir_fontconfig};
    # dir_texmfdist = [...BusytexPipeline.texmf_system, ...texmf_local].map(texmf => texmf + '/texmf-dist').join(':');
    # dir_texmfvar = '/texlive/texmf-dist/texmf-var';
    # dir_cnf = '/texlive/texmf-dist/web2c';
    # dir_fontconfig = '/etc/fonts';

    xdv_path, pdf_path, log_path, aux_path, blg_path, bbl_path = map(lambda ext: tex_relative_path.removesuffix('.tex') + ext, ['.xdv', '.pdf', '.log', '.aux', '.blg', '.bbl'])

    arg_pdftex_verbose = ['-kpathsea-debug', '32']
    arg_pdftex_debug = ['-kpathsea-debug', '63', '-recorder']
    arg_bibtex_verbose = ['--debug', 'search']
    arg_bibtex_debug = ['--debug', 'all']
    cmd_pdftex    = [busytex, 'pdflatex',   '--no-shell-escape', '--interaction=nonstopmode', '--halt-on-error', '--output-format=pdf', '--fmt', fmt, tex_relative_path]
    cmd_pdftex_not_final    = [busytex, 'pdflatex', '--no-shell-escape', '--interaction=batchmode', '--halt-on-error', '--fmt', fmt, tex_relative_path]
    cmd_bibtex = [busytex, 'bibtex8', '--8bit', tex_relative_path.removesuffix('.tex') + '.aux']

    logs = []
    
    if bibtex:
        cmd1res = subprocess.run(cmd_pdftex_not_final, env = env, cwd = cwd, capture_output = True)
        logs.append(dict(vars(cmd1res), has_error = has_error(cmd1res, error_messages_fatal)))
        cmd2res = subprocess.run(cmd_bibtex, env = env, cwd = cwd, capture_output = True)
        logs.append(dict(vars(cmd2res), has_error = has_error(cmd1res, error_messages_fatal)))
        cmd3res = subprocess.run(cmd_pdftex_not_final, env = env, cwd = cwd, capture_output = True)
        logs.append(dict(vars(cmd3res), has_error = has_error(cmd1res, error_messages_fatal)))
        cmd4res = subprocess.run(cmd_pdftex, env = env, cwd = cwd, capture_output = True)
        logs.append(dict(vars(cmd4res), has_error = has_error(cmd1res, error_messages_all)))
        
        # is_bibtex = cmd[0].startsWith('bibtex');
        #  logs.push({
        #      texmflog    : (verbose == BusytexPipeline.VerboseInfo || verbose == BusytexPipeline.VerboseDebug) ? this.read_all_text(FS, this.texmflog) : '',
        #      missfontlog : (verbose == BusytexPipeline.VerboseInfo || verbose == BusytexPipeline.VerboseDebug) ? this.read_all_text(FS, this.missfontlog) : '',
        #      log : read_all_text(is_bibtex ? blg_path : log_path).trim(),
        #      aux : read_all_text(is_bibtex ? bbl_path : aux_path).trim(),
        #  });

    else:
        cmd4res = subprocess.run(cmd_pdftex, env = env, cwd = cwd, capture_output = True)
        logs.append(dict(vars(cmd4res), has_error = has_error(cmd1res, error_messages_all)))

    logcat = '\n\n'.join('\n'.join(['$ ' + ' '.join(log['args']), 'EXITCODE: ' + str(log['returncode']), '', 'TEXMFLOG:', log.get('texmflog', ''), '==', 'MISSFONTLOG:', log.get('missfontlog', ''), '==', 'LOG:', log.get('log', ''), '==', 'STDOUT:', log['stdout'].decode('utf-8', errors = 'replace'), '==', 'STDERR:', log['stderr'].decode('utf-8', errors = 'replace'), '======']) for log in logs)

    return logs

def lualatex():
    luahbtex  = ['luahblatex', '--no-shell-escape', '--interaction=nonstopmode', '--halt-on-error', '--output-format=pdf', '--fmt', FMT, '--nosocket', tex_path]
    luahbtex_not_final  = ['luahblatex', '--no-shell-escape', '--interaction=nonstopmode', '--halt-on-error', '--no-pdf', '--fmt', FMT, '--nosocket', tex_path]
    luatex  = ['lualatex', '--no-shell-escape', '--interaction=nonstopmode', '--halt-on-error', '--output-format=pdf', '--fmt', FMT, '--nosocket', tex_path]
    luatex_not_final  = ['lualatex', '--no-shell-escape', '--interaction=nonstopmode', '--halt-on-error', '--no-pdf', '--fmt', FMT, '--nosocket', tex_path]
    pass
    


def prepare_tex_params(dirname):
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
#    if bibtex is None:
#        bibtex = any(bib_cmd in open(path).read() for path in file_paths if path.endswith('.tex') for bib_cmd in ['\\bibliography', '\\printbibliography'])
#        // files.some(({path, contents}) => contents != null && path.endsWith('.bib'));
#        bibtex = 
   
    prevcwd = os.getcwd()
    os.chdir(dirname)
    
    file_paths = [os.path.join(dirpath, f) for dirpath, dirnames, filenames in os.walk('.') for f in filenames]
    tex_relative_path = ([file_path for file_path in file_paths  for contents in [read_all_bytes(file_path)] if b'\\begin{document}' in contents] or [''])[0]
    has_bib_files = any(file_path.endswith('.bib') for file_path in file_paths)

    bibtex = any(bib_cmd in contents for file_path in file_paths if file_path.endswith('.tex') for contents in [read_all_bytes(file_path)] for bib_cmd in [b'\\bibliography', b'\\printbibliography'])
    #TODO: split running bibtex from running the other commands?

    
    tex_params = dict(bibtex = bibtex, tex_relative_path = tex_relative_path, cwd = dirname)
    
    os.chdir(prevcwd)
    return tex_params

def main(args):
    tex_params = prepare_tex_params(args.input_dir)
    for k in tex_params:
        if getattr(args, k, None):
            tex_params[k] = getattr(args, k)

    if not tex_params['tex_relative_path']:
        return print(args.input_dir, tex_params, False, 'FAIL', 'NOTEXPATH')

    if args.driver == 'pdflatex':
        logs = pdflatex(**tex_params, busytex = os.path.abspath(args.busytex), DIST = os.path.abspath(args.DIST))
        output_exists = os.path.exists(os.path.join(tex_params['cwd'], tex_params['tex_relative_path'].removesuffix('.tex') + '.pdf'))

        if logs[-1]['returncode'] == 0:
            return print(args.input_dir, tex_params, output_exists, 'OK')
        else:
            return print(args.input_dir, tex_params, output_exists, 'FAIL', logs[-1]['returncode'], os.listdir(tex_params['cwd']))


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--input-dir', '-i', required = True)
    parser.add_argument('--driver', default = '', choices = ['xelatex', 'pdflatex', ''])
    parser.add_argument('--busytex')
    parser.add_argument('--DIST')
    parser.add_argument('--tex-relative-path')
    parser.add_argument('--bibtex', action = 'store_true')
    args = parser.parse_args()
    main(args)
