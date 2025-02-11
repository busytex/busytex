# based on:
# https://ctan.org/pkg/latexmk/
# https://www.cantab.net/users/johncollins/latexmk/
# https://mirrors.ctan.org/support/latexmk/latexmk.pl
# https://mg.readthedocs.io/latexmk.html
# https://github.com/schlamar/latexmk.py -> https://github.com/JanKanis/latexmk.py
# https://metacpan.org/release/TSCHWAND/TeX-AutoTeX-v0.906.0/view/lib/TeX/AutoTeX/File.pm
# https://github.com/Mrmaxmeier/tectonic-on-arXiv/blob/master/report.py
# https://tex.stackexchange.com/a/118491/115598

#build/native/fonts.conf:
#	mkdir -p $(dir $@)
#	echo '<?xml version="1.0"?>'                          > $@
#	echo '<!DOCTYPE fontconfig SYSTEM "fonts.dtd">'      >> $@
#	echo '<fontconfig>'                                  >> $@
#	#<dir prefix="relative">../texlive-basic/texmf-dist/fonts/opentype</dir>
#	#<dir prefix="relative">../texlive-basic/texmf-dist/fonts/type1</dir>
#	#<cachedir prefix="relative">./cache</cachedir>
#	echo '</fontconfig>'                                 >> $@


import os
import sys
import glob
import argparse
import subprocess
import tarfile
import gzip
import io
import urllib.request
    
error_messages_fatal = [
    'LaTeX Error',
    'LaTeX Error: Invalid UTF-8 byte',
    'LaTeX Error: File', 
    'LaTeX Error: Unicode character',
    'LaTeX Error: Invalid UTF-8 byte',
    'LaTeX Error: Missing \\begin{document}', 
    '! Undefined control sequence.', 
    '! Bad character code', 
    'undefined old font command',
    "Something's wrong--perhaps a missing \\item",
    'Package inputenc Error: inputenc is not designed for xetex or luatex.', 
    '\\end{thebibliography}', 
    'not set up for use with LaTeX',
    'That was a fatal error', 
    'Fatal format file error',
    'Fatal error occurred', 
    
    'fork(): Function not implemented', # kpathsea
    'Appending font creation commands to', # kpathsea
    'kpathsea: Running mktexpk ', #kpathsea
    
    'Filtering file via command',
    ':fatal:',
    'Something is wrong. Are you sure this is a DVI file', # xdvipdfmx:fatal: 
    'passed invalid object',  # xdvipdfmx:fatal: 
    'Cannot proceed without .vf or \"physical\" font for PDF output...',  # xdvipdfmx:fatal: 
    'Could not locate a virtual/physical font for TFM', # xdvipdfmx:warning: 
    'There are no valid font mapping entry for this font', # xdvipdfmx:warning: 
    'was assumed but failed to locate that font', # xdvipdfmx:warning: 
    'Color stack underflow. Just ignore.', # xdvipdfmx:warning: 

    'busytexmk xetex error: no xdv file produced'
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

def log_cat_bytes(logs):
    return b'\n\n'.join(b'\n'.join([
        b'$ ' + ' '.join(log['args']).encode(), 
        b'EXITCODE: ' + str(log['returncode']).encode(), b'', 
        b'TEXMFLOG:', log.get('texmflog', b''), b'==', 
        b'MISSFONTLOG:', log.get('missfontlog', b''), b'==', 
        b'LOG:', log.get('log', b''), b'==', 
        b'STDOUT:', log['stdout'], b'==', 
        b'STDERR:', log['stderr'], b'======'
    ]) for log in logs)

def pdflatex(tex_relative_path, busytex, cwd, DIST, bibtex, log = None, pdf = None):
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

    with open(log or os.devnull, 'wb') as f:
        f.write(log_cat_bytes(logs))

    pdf_path = os.path.join(cwd, pdf_path)
    if os.path.exists(pdf_path) and pdf:
        with open(pdf, 'wb') as f, open(pdf_path, 'rb') as h:
            f.write(h.read())

    return logs

def xelatex(tex_relative_path, busytex, cwd, DIST, bibtex, log = None, pdf = None):
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
    
    cmd_xetex     = [busytex, 'xelatex', '--no-shell-escape', '--interaction=batchmode', '--halt-on-error', '--no-pdf', '--fmt', fmt , tex_relative_path] #TODO: nonstopmode?
    cmd_xdvipdfmx = [busytex, 'xdvipdfmx', '-o', pdf_path, xdv_path]

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

        if os.path.exists(os.path.join(cwd, xdv_path)):
            cmd5res = subprocess.run(cmd_xdvipdfmx, env = env, cwd = cwd, capture_output = True)
            logs.append(collect_logs(cmd5res, error_messages_all, aux_path))
        else:
            logs[-1]['stdout'] += b'\n' + error_messages_fatal[-1].encode()
            logs[-1]['has_error'] = True
    else:
        cmd4res = subprocess.run(cmd_pdftex, env = env, cwd = cwd, capture_output = True)
        logs.append(collect_logs(cmd4res, error_messages_all, aux_path))

        if os.path.exists(os.path.join(cwd, xdv_path)):
            cmd5res = subprocess.run(cmd_xdvipdfmx, env = env, cwd = cwd, capture_output = True)
            logs.append(collect_logs(cmd5res, error_messages_all, aux_path))
        else:
            logs[-1]['stdout'] += b'\n' + error_messages_fatal[-1].encode()
            logs[-1]['has_error'] = True

    with open(log or os.devnull, 'wb') as f:
        f.write(log_cat_bytes(logs))
    
    pdf_path = os.path.join(cwd, pdf_path)
    if os.path.exists(pdf_path) and pdf:
        with open(pdf, 'wb') as f, open(pdf_path, 'rb') as h:
            f.write(h.read())

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
    #    const main_tex_files = this.find(dirname, '', false).filter(f => f.contents != null && f.path.endsWith(this.tex_ext) && (f.path.includes('main') || f.path.includes(basename)));; default_path = main_tex_files.length > 0 ? main_tex_files[0].path : tex_files[0].path;
    #if(default_path == null)
    #{
    #    const text_files = this.find(dirname, '', false).filter(f => f.contents != null && this.text_extensions.some(ext => f.path.toLowerCase().endsWith(ext)));
    #    if(text_files.length == 1)
    #        default_path = text_files[0].path;
    #    else if(text_files.length > 1)
    #        const main_text_files = this.find(dirname, '', false).filter(f => f.contents != null && f.path.toUpperCase().includes('README')); default_path = main_text_files.length > 0 ? main_text_files[0].path : text_files[0].path;
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

def runtex(args, file = sys.stdout, sep = '\t'):
    assert args.input_dir and args.busytex

    tex_params = prepare_tex_params(args.input_dir)
    for k in tex_params:
        if getattr(args, k, None):
            tex_params[k] = getattr(args, k)

    if not tex_params['tex_relative_path']:
        with open(args.log if args.log else os.devnull, 'w') as f:
            print('NOTEXPATH', str(os.listdir(args.input_dir)), file = f)
        print(args.input_dir, 'FAIL', tex_params, False, 'NOTEXPATH', sep = sep, file = file)
        return 2

    if args.driver == 'pdflatex':
        logs = pdflatex(**tex_params, busytex = os.path.abspath(args.busytex), DIST = os.path.abspath(args.DIST), log = args.log, pdf = args.output_path)
        output_exists = os.path.exists(os.path.join(tex_params['cwd'], tex_params['tex_relative_path'].removesuffix('.tex') + '.pdf'))
        if logs[-1]['returncode'] == 0 and not logs[-1]['has_error']:
            print(args.input_dir, 'OK', tex_params, output_exists, args.log, sep = sep, file = file)
            return 0
        else:
            print(args.input_dir, 'FAIL', tex_params, output_exists, args.log, sep = sep, file = file)
            return 1
    
    if args.driver == 'xelatex':
        logs = xelatex(**tex_params, busytex = os.path.abspath(args.busytex), DIST = os.path.abspath(args.DIST), log = args.log, pdf = args.output_path)
        output_exists = os.path.exists(os.path.join(tex_params['cwd'], tex_params['tex_relative_path'].removesuffix('.tex') + '.pdf'))
        if logs[-1]['returncode'] == 0 and not logs[-1]['has_error']:
            print(args.input_dir, 'OK', tex_params, output_exists, args.log, sep = sep, file = file)
            return 0
        else:
            print(args.input_dir, 'FAIL', tex_params, output_exists, args.log, sep = sep, file = file)
            return 1



def main(args, sep = '\t', busytexmk_log = 'busytexmk.log'):
    if args.DIST and not args.busytex:
        args.busytex = os.path.join(args.DIST, 'busytex')
        
    if args.arxiv_id and args.tmp_dir:
        args.input_dir = os.path.join(args.tmp_dir, 'arxiv' + args.arxiv_id)
        os.makedirs(args.input_dir, exist_ok = True)
        resp = urllib.request.urlopen(urllib.request.Request(os.path.join('https://arxiv.org/src/', args.arxiv_id), headers = {'Accept-Encoding': 'gzip;'} ))
        data = resp.read()
        if resp.info().get('Content-Encoding') == 'gzip' or resp.info().get('Content-Type') == 'application/gzip':
            data = gzip.decompress(data)
        try:
            tarfile.open(fileobj = io.BytesIO(data)).extractall(args.input_dir)
        except:
            with open(os.path.join(args.input_dir, os.path.basename(args.input_dir) + '.tex'), 'wb') as f:
                f.write(data)
        return runtex(args)

    if args.arxiv_tar and args.tmp_dir:
        os.makedirs(args.log_ok_dir, exist_ok = True)
        os.makedirs(args.log_fail_dir, exist_ok = True)
        total, ok, fail, logsall = 0, 0, 0, []
        file = open(args.log, 'w')
        for tar_path in args.arxiv_tar:
            tar = tarfile.open(tar_path)
            for member in tar.getmembers():
                if not member.name.endswith('.gz'):
                    continue
                data = gzip.open(tar.extractfile(member)).read()
                args.input_dir = os.path.join(args.tmp_dir, member.name)
                args.log = os.path.join(args.input_dir, busytexmk_log)
                os.makedirs(args.input_dir, exist_ok = True)
                try:
                    tarfile.open(fileobj = io.BytesIO(data)).extractall(args.input_dir)
                except:
                    with open(os.path.join(args.input_dir, os.path.basename(args.input_dir) + '.tex'), 'wb') as f:
                        f.write(data)
                returncode = runtex(args, file = file)
                total += 1
                ok += returncode == 0
                fail += returncode != 0

                with open(args.log, 'rb') as f, open(os.path.join(args.log_ok_dir if returncode == 0 else args.log_fail_dir, os.path.basename(args.input_dir) + '_' + busytexmk_log), 'wb') as h:
                    logsall.append(f.read())
                    h.write(logsall[-1])
                if args.tmp_dir_delete:
                    for cur, dirs, files in os.walk(args.input_dir, topdown = False):
                        for f in files:
                            os.remove(os.path.join(cur, f))
                        for d in dirs:
                            if os.path.exists(os.path.join(cur, d)):
                                os.rmdir(os.path.join(cur, d))
                        os.rmdir(cur)
                    
        
        for err in error_messages_fatal:
            print(err, sum(err.encode() in log for log in logsall), sep = sep)
        for err in [b"LaTeX Error", b":fatal:", b"Filtering file via command", b"kpathsea: Running"]:
            sys.stdout.buffer.write(b'\n'.join(line for log in logsall for line in log.splitlines() if err in line))
        sys.stdout.buffer.write(f'\n{total=} {ok=} {fail=}\n'.encode())
        return
    
    if args.input_tar_gz and args.tmp_dir:
        args.input_dir = os.path.join(args.tmp_dir, os.path.basename(args.input_tar_gz))
        os.makedirs(args.input_dir, exist_ok = True)
        data = gzip.open(args.input_tar_gz).read()
        try:
            tarfile.open(fileobj = io.BytesIO(data)).extractall(args.input_dir)
        except:
            with open(os.path.join(args.input_dir, os.path.basename(args.input_dir) + '.tex'), 'wb') as f:
                f.write(data)
        # data = gzip.open(tar.extractfile(tar.getmember(args.input_gz))).read()
        return runtex(args)
    
    if args.input_dir:
        return runtex(args)


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--input-dir', '-i')
    parser.add_argument('--output-path', '-o')
    parser.add_argument('--input-tar-gz')
    parser.add_argument('--arxiv-tar', nargs = '*', default = [])
    parser.add_argument('--arxiv-id')
    
    parser.add_argument('--tmp-dir', default = '.busytexmk')
    parser.add_argument('--tmp-dir-delete', action = 'store_true')
    parser.add_argument('--driver', default = '', choices = ['xelatex', 'pdflatex', ''])
    parser.add_argument('--busytex')
    parser.add_argument('--DIST')
    parser.add_argument('--tex-relative-path')
    parser.add_argument('--bibtex', action = 'store_true')
    parser.add_argument('--log')
    parser.add_argument('--log-ok-dir', default = 'OK')
    parser.add_argument('--log-fail-dir', default = 'FAIL')
    args = parser.parse_args()
    main(args)
