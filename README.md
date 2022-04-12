# Programs from TexLive 2021 compiled with Emscripten into a single fully static binary (x86_64-linux / WASM)

Currently compiles into a **fully static binary** (via musl on Alpine Linux):
- xetex
- pdftex
- luahbtex
- bibtex8
- xdvipdfmx
- kpsewhich, kpsestat, kpseaccess, kpsereadlink
- makeindex

Supported architecture targets:
- x86_64-linux
- WASM

Future work:
- mf-nowin
- LuaMetaTex / LMTX (lua)
- tlmgr (perl, web requests)
- Biber (perl)
- mktexlsr, fmtutil, updmap (perl)

### Usage
```shell
# wasm version, download latest compiled assets, launch the web server example.py and then go to http://localhost:8080/example/example.html
mkdir -p dist
wget -P dist --backups=1 $(printf "https://github.com/busytex/busytex/releases/latest/download/%s " busytex_pipeline.js busytex_worker.js    busytex.wasm busytex.js texlive-basic.js texlive-basic.data    ubuntu-texlive-latex-extra.data ubuntu-texlive-latex-extra.js    ubuntu-texlive-latex-recommended.data ubuntu-texlive-latex-recommended.js    ubuntu-texlive-science.data ubuntu-texlive-science.js)
python3 example/example.py

# native version
sh example/example.sh
```

### Help needed
- refactor data packages subsystem in Emscripten: https://github.com/emscripten-core/emscripten/issues/14385
- LLVM's support for localizing global system in WASM object files: https://bugs.llvm.org/show_bug.cgi?id=51279
- upstream build sequence to TexLive: https://tug.org/pipermail/tlbuild/2021q1/004806.html
- various Emscripten improvements: https://github.com/emscripten-core/emscripten/issues/12093, https://github.com/emscripten-core/emscripten/issues/12256, https://github.com/emscripten-core/emscripten/issues/13466, https://github.com/emscripten-core/emscripten/issues/13219
- better error catching at all stages including WASM module initialization: https://github.com/emscripten-core/emscripten/issues/14777
- explore defining DLLPROC instead of redefining main functions
- complete investigation of feasibility of porting Biber to WASM/browser: https://github.com/plk/biber/issues/338, https://github.com/busytex/buildbiber
- review shipped TexLive packages in order to review useless files to save space
- review fonts / fontmaps / hyphenation shipped in TexLive packages
- optimizing binary size. any stripping possible?
- compile for x86_64-linux-glibc with clang (to match WASM toolchain)
- set up x86_64-linux binaries Github Actions test for WSLv1
- minimize build sequence in Makefile as much as possible
- test of WASM binaries using node.js, test preloading of data packages
- preloaded minimal single-file, single-engine versions (both WASM and x86_64-linux) with just TexLive Basic and latex-base
- explore creating virtual and LD_PRELOAD-based file systems: to avoid unpacking the ISO files or ZIP files (to be used even outside BusyTeX context); to embed Tex packages / Perl scripts in the native build 
- figure out how to embed static perl with Perl scripts (fmtutil.pl, updmap.pl, https://perldoc.perl.org/perlembed#Using-embedded-Perl-with-POSIX-locales, https://www.cs.ait.ac.th/~on/O/oreilly/perl/advprog/ch19_02.htm, https://www.foo.be/docs/tpj/issues/vol1_4/tpj0104-0009.html, http://www.kaiyuanba.cn/content/develop/Perl/Extending_And_Embedding_Perl.pdf)
- pre-parse ProvidesPackage meta for data packages

### Building from source
```shell
# install dependencies: wget, cmake, gperf, p7zip-full, emscripten
apt-get install wget cmake gperf p7zip-full 
git clone https://github.com/emscripten-core/emsdk
cd emsdk
./emsdk update-tags
./emsdk install tot
./emsdk activate tot
source emsdk_env.sh

# clone busytex
git clone https://github.com/busytex/busytex
cd busytex

# set make parallelism
export MAKEFLAGS=-j8

# download and patch texlive into ./source
make texlive

# build native tools and fonts file into ./build/native
make native

# smoke test native binaries
make test

# build wasm tools into ./build/wasm
make wasm

# build TeX Directory Structure (TDS)
make tds-basic

# test native binaries
sh example/example.sh

# reproduce and pack Ubuntu TexLive packages into wasm data files
make build/wasm/texlive-basic.js

# copies binaries and TexLive TDS into ./dist
make dist-native dist-wasm

# remove ./build and ./source completely
make clean
```

### Virtual and LD_PRELOAD readonly file system (reading ISO / TAR / ZIP)
- LD_PRELOAD FS that could work with package zip archvies (CTAN? ftp://tug.org/texlive/Contents/live/texmf-dist/)
- LD_PRELOAD FS that could work with texlive iso files containing zip archives
- virtual FS for reading ISO/TAR/ZIP texlive TDS
- virtual FS for reading Perl scripts
- virtual FS for embedding small TDS into binaries
- https://github.com/erincandescent/lib9660/blob/master/tb9660.c
- https://github.com/jacereda/fsatrace
- https://github.com/fritzw/ld-preload-open/blob/master/path-mapping.c
- https://github.com/mikix/deb2snap/blob/master/src/preload.c#L84
- https://lists.ubuntu.com/archives/snappy-devel/2015-February/000282.html
- https://www.tomaz.me/2014/01/08/detecting-which-process-is-creating-a-file-using-ld-preload-trick.html
- https://github.com/AppImage/AppImageKit/issues/267
- http://avf.sourceforge.net/
- https://gist.github.com/przemoc/571086
- https://adared.ch/unionfs_by_intercept/
- https://arxiv.org/abs/1908.10740
- http://ordiluc.net/fs/libetc/
- http://pages.stern.nyu.edu/~marriaga/software/libtrash/

### Random links
- abspath/realpath instead of ROOT
- instruction for local tlmgr install like tinytex
- https://github.com/emscripten-core/emscripten/issues/11709#issuecomment-663901019
- location of hyphen.cfg file? https://tex.loria.fr/ctan-doc/macros/latex/doc/html/cfgguide/node11.html
- https://en.wikibooks.org/wiki/LaTeX/Installing_Extra_Packages
- https://github.com/emscripten-core/emscripten/pull/4737
- https://ctan.crest.fr/tex-archive/macros/latex/contrib/
- http://tug.org/texmf-dist/scripts/texlive/
- http://tug.ctan.org/systems/texlive/tlnet/tlpkg/
- ftp://tug.org/texlive/Contents/live/texmf-dist/
- ftp://tug.org/texlive/historic/2020/texlive-20200406-texmf.tar.xz 
- ftp://tug.org/texlive/historic/2020/texlive-20200406-tlpdb-full.tar.gz
- LMTX: https://tug.org/TUGboat/tb40-1/tb124hagen-lmtx.pdf
- Emscripten allocator: https://github.com/Sable/emscripten_malloc
- String and pool files: http://www.readytext.co.uk/?p=3590
- Pascal compiler: https://ctan.org/tex-archive/systems/unix/tex-fpc?lang=en
- Biber: https://meeting.contextgarden.net/2011/talks/day1_07_jean-michel_bibliography/hc-bb-1.pdf

### Example of lazy files
```make
dist/texlive-lazy.js:
    mkdir -p $(dir $@)
    -rm -rf dist/texmf
    $(PYTHON) lazy_packager.py dist --js-output=$@ --export-name=BusytexPipeline \
        --preload build/texlive-full/texmf-dist/tex/latex/titlesec@/texmf/texmf-dist/tex/latex/titlesec \
        --preload build/texlive-full/texmf-dist/tex/latex/xcolor@/texmf/texmf-dist/tex/latex/xcolor \
        --preload build/texlive-full/texmf-dist/tex/latex/etoolbox@/texmf/texmf-dist/tex/latex/etoolbox \
        --preload build/texlive-full/texmf-dist/tex/latex/footmisc@/texmf/texmf-dist/tex/latex/footmisc \
        --preload build/texlive-full/texmf-dist/tex/latex/textpos@/texmf/texmf-dist/tex/latex/textpos \
        --preload build/texlive-full/texmf-dist/tex/latex/ms@/texmf/texmf-dist/tex/latex/ms \
        --preload build/texlive-full/texmf-dist/tex/latex/parskip@/texmf/texmf-dist/tex/latex/parskip
```

### References
- [pdftex.js](https://github.com/dmonad/pdftex.js)
- [xetex.js](https://github.com/lyze/xetex-js)
- [texlive.js](https://github.com/manuels/texlive.js/)
- [latexjs](https://github.com/latexjs/latexjs)
- [dvi2html](https://github.com/kisonecat/dvi2html), [web2js](https://github.com/kisonecat/web2js)
- [SwiftLaTeX](https://github.com/SwiftLaTeX/SwiftLaTeX)
- [JavascriptSubtitlesOctopus](https://github.com/Dador/JavascriptSubtitlesOctopus)
- [js-sha1](https://raw.githubusercontent.com/emn178/js-sha1)
- [BLFS](http://www.linuxfromscratch.org/blfs/view/svn/pst/texlive.html)
