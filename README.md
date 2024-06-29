# Programs from TexLive 2023 compiled with Emscripten into a single fully static binary (x86_64-linux / WASM)

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
- WASM32

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

```shell
wget http://mirrors.ctan.org/systems/texlive/Images/texlive2023-20230313.iso
split -b2G -d texlive2023-20230313.iso texlive2023-20230313.iso.
```

### Help needed
- single page HTML5 webapp: https://diveinto.html5doctor.com/offline.html
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
- https://github.com/schlamar/latexmk.py/pull/11
- https://github.com/schlamar/latexmk.py
- https://github.com/JanKanis/latexmk.py
- https://mg.readthedocs.io/latexmk.html
- https://ctan.org/tex-archive/support/latexmk
- https://metacpan.org/release/TSCHWAND/TeX-AutoTeX-v0.906.0/view/lib/TeX/AutoTeX/File.pm
