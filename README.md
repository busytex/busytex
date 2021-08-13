# xetex+bibtex from TexLive2021 compiled with Emscripten into a single WebAssembly file

Currently compiles:
- xetex
- bibtex8
- xdvipdfmx
- kpsewhich

Future work:
- pdftex
- kpsestat
- makeindex
- tlmgr (web requests)
- LuaTex / LMTX (lua)
- Biber (perl)

### Dependencies
```shell
# install dependencies
apt-get install wget cmake

# install and activate emscripten
git clone https://github.com/emscripten-core/emsdk
cd emsdk
./emsdk update-tags
./emsdk install tot
./emsdk activate tot
source emsdk_env.sh
```

### Installation
```shell

# clone busytex
git clone https://github.com/busytex/busytex
cd busytex

# set make parallelism
export MAKEFLAGS=-j8

# download and patch texlive source
make texlive

# build native tools
make native

# build native fonts file
make build/native/fonts.conf

# build TeX Directory Structure (TDS) and latex format file (latex.fmt)
make tds-basic

# build wasm tools
make wasm

# pack TDS into wasm data files
make tds-wasm

# reproduce and pack Ubuntu TexLive packages into wasm data files
make ubuntu-wasm

# copies binaries and TexLive TDS into ./dist
make dist

# remove build and source completely
make clean
```

### Usage
```shell
# wasm version, download latest compiled assets, launch server.py and then go to http://localhost:8080/example/example.html
mkdir -p dist
wget -P dist --backups=1 $(printf "https://github.com/busytex/busytex/releases/latest/download/%s " busytex_pipeline.js busytex_worker.js    busytex.wasm busytex.js texlive-basic.js texlive-basic.data    ubuntu-texlive-latex-base.data ubuntu-texlive-latex-base.js    ubuntu-texlive-latex-extra.data ubuntu-texlive-latex-extra.js    ubuntu-texlive-latex-recommended.data ubuntu-texlive-latex-recommended.js    ubuntu-texlive-science.data ubuntu-texlive-science.js)
python3 example/serve.py

# native version
bash example/example.sh
```




### References
- [texlive.js](https://github.com/manuels/texlive.js/)
- [xetex.js](https://github.com/lyze/xetex-js)
- [dvi2html](https://github.com/kisonecat/dvi2html), [web2js](https://github.com/kisonecat/web2js)
- [SwiftLaTeX](https://github.com/SwiftLaTeX/SwiftLaTeX)
- [JavascriptSubtitlesOctopus](https://github.com/Dador/JavascriptSubtitlesOctopus)
- [js-sha1](https://raw.githubusercontent.com/emn178/js-sha1)

### TODO
```shell
xpdf-src/xpdf/

https://github.com/rurban/perl-compiler
http://www.linuxfromscratch.org/blfs/view/svn/pst/texlive.html
#TODO: native busytex: + CSFINPUT/fontconfig.conf//'--csfile', '/bibtex/88591lat.csf'
#TODO: abspath/realpath instead of ROOT

# https://ctan.tetaneutral.net/systems/texlive/Images/texlive2020-20200406.iso
# http://www.tug.org/texlive/devsrc/Master/tlpkg/tlpsrc/collection-basic.tlpsrc
#TODO: custom binaries for install-tl
#TODO: instruction for local tlmgr install tinytex
#TODO: install-tl install from local full download

#TODO: custom FS that could work with package zip archvies (CTAN? ftp://tug.org/texlive/Contents/live/texmf-dist/)
#TODO: https://github.com/emscripten-core/emscripten/issues/11709#issuecomment-663901019
# https://github.com/erincandescent/lib9660/blob/master/tb9660.c
# https://en.wikibooks.org/wiki/LaTeX/Installing_Extra_Packages
# https://github.com/emscripten-core/emscripten/pull/4737

# https://blog.jcoglan.com/2017/03/22/myers-diff-in-linear-space-theory/
# http://www.xmailserver.org/xdiff-lib.html

#TODO: location of hyphen.cfg file? https://tex.loria.fr/ctan-doc/macros/latex/doc/html/cfgguide/node11.html
# https://ctan.crest.fr/tex-archive/macros/latex/contrib/
# http://tug.org/texmf-dist/
# ftp://tug.org/texlive/Contents/live/texmf-dist/
# ftp://tug.org/texlive/historic/2020/texlive-20200406-texmf.tar.xz 
# ftp://tug.org/texlive/historic/2020/texlive-20200406-tlpdb-full.tar.gz
# texmf-dist/scripts/texlive/tlmgr.pl
# http://tug.org/texmf-dist/scripts/texlive/
# https://fossies.org/linux/misc/install-tl-unx.tar.gz/
# http://tug.ctan.org/systems/texlive/tlnet/tlpkg/
```

### Links
https://www.overleaf.com/learn/latex/Articles/The_two_modes_of_TeX_engines:_INI_mode_and_production_mode

https://tug.org/TUGboat/tb40-1/tb124hagen-lmtx.pdf

https://github.com/Sable/emscripten_malloc

https://github.com/dmonad/pdftex.js

http://www.readytext.co.uk/?p=3590

https://github.com/skalogryz/wasmbin

https://ctan.org/tex-archive/systems/unix/tex-fpc?lang=en

https://github.com/mikix/deb2snap/blob/master/src/preload.c#L84

https://lists.ubuntu.com/archives/snappy-devel/2015-February/000282.html

https://www.tomaz.me/2014/01/08/detecting-which-process-is-creating-a-file-using-ld-preload-trick.html

https://github.com/AppImage/AppImageKit/issues/267

http://avf.sourceforge.net/

https://arxiv.org/pdf/1908.10740.pdf

https://github.com/jacereda/fsatrace

https://github.com/fritzw/ld-preload-open/blob/master/path-mapping.c

https://adared.ch/unionfs_by_intercept/

https://gist.github.com/przemoc/571086

http://ordiluc.net/fs/libetc/

https://meeting.contextgarden.net/2011/talks/day1_07_jean-michel_bibliography/hc-bb-1.pdf

```
.PHONY: dist/texlive-lazy.js
dist/texlive-lazy.js:
    mkdir -p $(dir $@)
    rm -rf dist/texmf || true
    $(PYTHON) lazy_packager.py dist --js-output=$@ --export-name=BusytexPipeline \
        --preload build/texlive-full/texmf-dist/tex/latex/titlesec@/texmf/texmf-dist/tex/latex/titlesec \
        --preload build/texlive-full/texmf-dist/tex/latex/xcolor@/texmf/texmf-dist/tex/latex/xcolor \
        --preload build/texlive-full/texmf-dist/tex/latex/etoolbox@/texmf/texmf-dist/tex/latex/etoolbox \
        --preload build/texlive-full/texmf-dist/tex/latex/footmisc@/texmf/texmf-dist/tex/latex/footmisc \
        --preload build/texlive-full/texmf-dist/tex/latex/textpos@/texmf/texmf-dist/tex/latex/textpos \
        --preload build/texlive-full/texmf-dist/tex/latex/ms@/texmf/texmf-dist/tex/latex/ms \
        --preload build/texlive-full/texmf-dist/tex/latex/parskip@/texmf/texmf-dist/tex/latex/parksip

```
