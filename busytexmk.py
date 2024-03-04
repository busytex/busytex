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
    
error_messages_fatal = [
    'Fatal error occurred', 
    'That was a fatal error', 
    ':fatal:', 
    '! Undefined control sequence.', 
    '! Bad character code', 
    'undefined old font command',
    'LaTeX Error: Invalid UTF-8 byte',
    'LaTeX Error',
    "Something's wrong--perhaps a missing \\item",
    'Cannot proceed without .vf or \"physical\" font for PDF output...', 
    'LaTeX Error: File', 
    'Package inputenc Error: inputenc is not designed for xetex or luatex.', 
    'LaTeX Error: Missing \\begin{document}', 
    '\\end{thebibliography}', 
    'That was a fatal error',
    'Fatal format file error',
    
    'Could not locate a virtual/physical font for TFM', # xdvipdfmx:warning: 
    'There are no valid font mapping entry for this font', # xdvipdfmx:warning: 
    'was assumed but failed to locate that font', # xdvipdfmx:warning: 
    'Color stack underflow. Just ignore.', # xdvipdfmx:warning: 
]
error_messages_extra = [
    'no output PDF file produced', 
    'No output PDF file written',
    'No pages of output.'
]

error_messages_all = error_messages_extra + error_messages_fatal

has_error = lambda cmdres, errors: any(e.encode() in cmdres.stdout + cmdres.stderr for e in errors)

SOURCE_DATE_EPOCH = 1234567890

FONTCONFIG_DEBUG_MATCH     =       1   # Brief information about font matching
FONTCONFIG_DEBUG_MATCHV    =       2   # Extensive font matching information
FONTCONFIG_DEBUG_EDIT      =       4   # Monitor match/test/edit execution
FONTCONFIG_DEBUG_FONTSET   =       8   # Track loading of font information at startup
FONTCONFIG_DEBUG_CACHE     =      16   # Watch cache files being written
FONTCONFIG_DEBUG_CACHEV    =      32   # Extensive cache file writing information
FONTCONFIG_DEBUG_PARSE     =      64   # (no longer in use)
FONTCONFIG_DEBUG_SCAN      =     128   # Watch font files being scanned to build caches
FONTCONFIG_DEBUG_SCANV     =     256   # Verbose font file scanning information
FONTCONFIG_DEBUG_MEMORY    =     512   # Monitor fontconfig memory usage
FONTCONFIG_DEBUG_CONFIG    =    1024   # Monitor which config files are loaded
FONTCONFIG_DEBUG_LANGSET   =    2048   # Dump char sets used to construct lang values
FONTCONFIG_DEBUG_OBJTYPES  =    4096   # Display message when value typechecks fail


KPSE_DEBUG_STAT   = 1
KPSE_DEBUG_HASH   = 2
KPSE_DEBUG_FOPEN  = 4
KPSE_DEBUG_PATHS  = 8
KPSE_DEBUG_EXPAND = 16
KPSE_DEBUG_SEARCH = 32
KPSE_DEBUG_VARS   = 64

KPSE_DEBUG_EVERYTHING = -1

def read_all_bytes(path):
    if not os.path.exists(path):
        return b''
    with open(path, 'rb') as f:
        return f.read()

def pdflatex(tex_relative_path, busytex, cwd, DIST, bibtex, log = None):
    # http://tug.ctan.org/info/tex-font-errors-cheatsheet/tex-font-cheatsheet.pdf 
    texmflog = 'texmf.log' # /tmp/texmf.log
    missfontlog = 'missfont.log'
    fmt = os.path.join(DIST, 'pdflatex.fmt')
    pdf_path, log_path, aux_path, blg_path, bbl_path = [tex_relative_path.removesuffix('.tex') + ext for ext in ['.pdf', '.log', '.aux', '.blg', '.bbl']] # https://github.com/github/gitignore/blob/main/TeX.gitignore

    env = dict(
        TEXMFDIST         = os.path.join(DIST, 'texlive/texmf-dist'), # ':'.join(os.path.join(texmf, 'texmf-dist') for texmf in texmf_system + texmf_local])
        TEXMFCNF          = os.path.join(DIST, 'texlive/texmf-dist/web2c'),
        TEXMFVAR          = os.path.join(DIST, 'texlive/texmf-dist/texmf-var'), # TODO: change to a separate out-of-tree non-readonly directory
        TEXMFLOG          = texmflog, 
        FONTCONFIG_PATH   = DIST, # /etc/fonts
        FC_DEBUG          = str(FONTCONFIG_DEBUG_MATCHV),# https://www.freedesktop.org/software/fontconfig/fontconfig-user.html
        SOURCE_DATE_EPOCH = str(SOURCE_DATE_EPOCH) # https://wiki.debian.org/ReproducibleBuilds/TimestampsInPDFGeneratedByLaTeX
    )

    collect_logs = lambda cmdres, errors, aux_path = '': dict( vars(cmdres), has_error = has_error(cmdres, errors), texlog = read_all_bytes(log_path), biblog = read_all_bytes(blg_path), texmflog = read_all_bytes(texmflog), missfontlog = read_all_bytes(missfontlog), aux = read_all_bytes(aux_path) )

    arg_pdftex_verbose = ['-kpathsea-debug', str(KPSE_DEBUG_SEARCH)] # https://www.tug.org/texinfohtml/kpathsea.html#Debugging You can get this by setting the environment variable KPATHSEA_DEBUG to ‘-1’
    arg_pdftex_debug = ['-kpathsea-debug', str(KPSE_DEBUG_EVERYTHING), '-recorder']
    arg_bibtex_verbose = ['--debug', 'search']
    arg_bibtex_debug = ['--debug', 'all']
    cmd_pdftex    = [busytex, 'pdflatex',   '--no-shell-escape', '--interaction=nonstopmode', '--halt-on-error', '--output-format=pdf', '--fmt', fmt, tex_relative_path]
    cmd_pdftex_not_final    = [busytex, 'pdflatex', '--no-shell-escape', '--interaction=batchmode', '--halt-on-error', '--fmt', fmt, tex_relative_path]
    cmd_bibtex = [busytex, 'bibtex8', '--8bit', tex_relative_path.removesuffix('.tex') + '.aux']

    logs = []
    
    if bibtex:
        cmd1res = subprocess.run(cmd_pdftex_not_final, env = env, cwd = cwd, capture_output = True)
        logs.append(collect_logs(cmd1res, error_messages_fatal, aux_path))
        
        cmd2res = subprocess.run(cmd_bibtex, env = env, cwd = cwd, capture_output = True)
        logs.append(collect_logs(cmd2res, error_messages_fatal, bbl_path))
        
        cmd3res = subprocess.run(cmd_pdftex_not_final, env = env, cwd = cwd, capture_output = True)
        logs.append(collect_logs(cmd3res, error_messages_fatal, aux_path))
        
        cmd4res = subprocess.run(cmd_pdftex, env = env, cwd = cwd, capture_output = True)
        logs.append(collect_logs(cmd4res, error_messages_all, aux_path))

    else:
        cmd4res = subprocess.run(cmd_pdftex, env = env, cwd = cwd, capture_output = True)
        logs.append(collect_logs(cmd4res, error_messages_all, aux_path))

    if log:
        logcat = b'\n\n'.join(b'\n'.join([
                b'$ ' + ' '.join(log['args']).encode(), 
                b'EXITCODE: ' + str(log['returncode']).encode(), 
                b'', 
                b'TEXMFLOG:', 
                log.get('texmflog', b''), 
                b'==', 
                b'MISSFONTLOG:', 
                log.get('missfontlog', b''), 
                b'==', 
                b'LOG:', 
                log.get('log', b''), 
                b'==', 
                b'STDOUT:', 
                log['stdout'], 
                b'==', 
                b'STDERR:', 
                log['stderr'], 
                b'======'
            ]) for log in logs)

        with open(log, 'wb') as f:
            f.write(logcat)
    
    return logs

def xelatex(tex_relative_path, busytex, cwd, DIST, bibtex, log = None):
    # http://tug.ctan.org/info/tex-font-errors-cheatsheet/tex-font-cheatsheet.pdf 
    texmflog = 'texmf.log' # /tmp/texmf.log
    missfontlog = 'missfont.log'
    fmt = os.path.join(DIST, 'xelatex.fmt')
    pdf_path, log_path, aux_path, blg_path, bbl_path, xdv_path  = [tex_relative_path.removesuffix('.tex') + ext for ext in ['.pdf', '.log', '.aux', '.blg', '.bbl', '.xdv', ]] # https://github.com/github/gitignore/blob/main/TeX.gitignore

    env = dict(
        TEXMFDIST         = os.path.join(DIST, 'texlive/texmf-dist'), # ':'.join(os.path.join(texmf, 'texmf-dist') for texmf in texmf_system + texmf_local])
        TEXMFCNF          = os.path.join(DIST, 'texlive/texmf-dist/web2c'),
        TEXMFVAR          = os.path.join(DIST, 'texlive/texmf-dist/texmf-var'), # TODO: change to a separate out-of-tree non-readonly directory
        TEXMFLOG          = texmflog, 
        FONTCONFIG_PATH   = DIST, # /etc/fonts
        FC_DEBUG          = str(FONTCONFIG_DEBUG_MATCHV),# https://www.freedesktop.org/software/fontconfig/fontconfig-user.html
        SOURCE_DATE_EPOCH = str(SOURCE_DATE_EPOCH) # https://wiki.debian.org/ReproducibleBuilds/TimestampsInPDFGeneratedByLaTeX
    )

    collect_logs = lambda cmdres, errors, aux_path = '': dict( vars(cmdres), has_error = has_error(cmdres, errors), texlog = read_all_bytes(log_path), biblog = read_all_bytes(blg_path), texmflog = read_all_bytes(texmflog), missfontlog = read_all_bytes(missfontlog), aux = read_all_bytes(aux_path) )

    arg_xdvipdfmx_verbose = ['--kpathsea-debug', str(KPSE_DEBUG_SEARCH), '-v']
    arg_xdvipdfmx_debug = ['--kpathsea-debug', str(KPSE_DEBUG_EVERYTHING), '-vv']
    
    arg_xetex_verbose = ['-kpathsea-debug', str(KPSE_DEBUG_SEARCH)] # https://www.tug.org/texinfohtml/kpathsea.html#Debugging You can get this by setting the environment variable KPATHSEA_DEBUG to ‘-1’
    arg_xetex_debug = ['-kpathsea-debug', str(KPSE_DEBUG_EVERYTHING), '-recorder']
    arg_bibtex_verbose = ['--debug', 'search']
    arg_bibtex_debug = ['--debug', 'all']
    cmd_bibtex = [busytex, 'bibtex8', '--8bit', tex_relative_path.removesuffix('.tex') + '.aux']
    
    cmd_xetex     = [busytex, 'xelatex' ,   '--no-shell-escape', '--interaction=batchmode', '--halt-on-error', '--no-pdf'           , '--fmt', this.fmt.xetex , tex_path] #TODO: nonstopmode?
    cmd_xdvipdfmx = ['xdvipdfmx', '-o', pdf_path, xdv_path]

    logs = []
    
    if bibtex:
        cmd1res = subprocess.run(cmd_xetex, env = env, cwd = cwd, capture_output = True)
        logs.append(collect_logs(cmd1res, error_messages_fatal, aux_path))
        
        cmd2res = subprocess.run(cmd_bibtex, env = env, cwd = cwd, capture_output = True)
        logs.append(collect_logs(cmd2res, error_messages_fatal, bbl_path))
        
        cmd3res = subprocess.run(cmd_xetex, env = env, cwd = cwd, capture_output = True)
        logs.append(collect_logs(cmd3res, error_messages_fatal, aux_path))
        
        cmd4res = subprocess.run(cmd_xetex, env = env, cwd = cwd, capture_output = True)
        logs.append(collect_logs(cmd4res, error_messages_all, aux_path))

        cmd5res = subprocess.run(cmd_xdvipdfmx, env = env, cwd = cwd, capture_output = True)
        logs.append(collect_logs(cmd5res, error_messages_all, aux_path))
    else:
        cmd4res = subprocess.run(cmd_pdftex, env = env, cwd = cwd, capture_output = True)
        logs.append(collect_logs(cmd4res, error_messages_all, aux_path))

        cmd5res = subprocess.run(cmd_xdvipdfmx, env = env, cwd = cwd, capture_output = True)
        logs.append(collect_logs(cmd5res, error_messages_all, aux_path))

    if log:
        logcat = b'\n\n'.join(b'\n'.join([
                b'$ ' + ' '.join(log['args']).encode(), 
                b'EXITCODE: ' + str(log['returncode']).encode(), 
                b'', 
                b'TEXMFLOG:', 
                log.get('texmflog', b''), 
                b'==', 
                b'MISSFONTLOG:', 
                log.get('missfontlog', b''), 
                b'==', 
                b'LOG:', 
                log.get('log', b''), 
                b'==', 
                b'STDOUT:', 
                log['stdout'], 
                b'==', 
                b'STDERR:', 
                log['stderr'], 
                b'======'
            ]) for log in logs)

        with open(log, 'wb') as f:
            f.write(logcat)
    
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
    #if bibtex is None:
    #    bibtex = any(bib_cmd in open(path).read() for path in file_paths if path.endswith('.tex') for bib_cmd in ['\\bibliography', '\\printbibliography'])
    #    // files.some(({path, contents}) => contents != null && path.endsWith('.bib'));
   
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
    if not args.input_dir:
        return print('\n'.join(error_messages_fatal))

    tex_params = prepare_tex_params(args.input_dir)
    for k in tex_params:
        if getattr(args, k, None):
            tex_params[k] = getattr(args, k)

    if not tex_params['tex_relative_path']:
        if args.log: print('NOTEXPATH', str(os.listdir(args.input_dir)), file = open(args.log, 'w'))
        return print(args.input_dir, 'FAIL', tex_params, False, 'NOTEXPATH')

    if args.driver == 'pdflatex':
        logs = pdflatex(**tex_params, busytex = os.path.abspath(args.busytex), DIST = os.path.abspath(args.DIST), log = args.log)
        output_exists = os.path.exists(os.path.join(tex_params['cwd'], tex_params['tex_relative_path'].removesuffix('.tex') + '.pdf'))
        if logs[-1]['returncode'] == 0 and not logs[-1]['has_error']:
            return print(args.input_dir, 'OK', tex_params, output_exists, args.log)
        else:
            return print(args.input_dir, 'FAIL', tex_params, output_exists, args.log)
    
    if args.driver == 'xelatex':
        logs = xelatex(**tex_params, busytex = os.path.abspath(args.busytex), DIST = os.path.abspath(args.DIST), log = args.log)
        output_exists = os.path.exists(os.path.join(tex_params['cwd'], tex_params['tex_relative_path'].removesuffix('.tex') + '.pdf'))
        if logs[-1]['returncode'] == 0 and not logs[-1]['has_error']:
            return print(args.input_dir, 'OK', tex_params, output_exists, args.log)
        else:
            return print(args.input_dir, 'FAIL', tex_params, output_exists, args.log)


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--input-dir', '-i')
    parser.add_argument('--driver', default = '', choices = ['xelatex', 'pdflatex', ''])
    parser.add_argument('--busytex')
    parser.add_argument('--DIST')
    parser.add_argument('--tex-relative-path')
    parser.add_argument('--bibtex', action = 'store_true')
    parser.add_argument('--log')
    args = parser.parse_args()
    main(args)
