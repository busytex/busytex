# xetex+bibtex from TexLive2020 compiled with Emscripten into a single WebAssembly file

Currently compiles:
- xetex
- bibtex8

Future work:
- tlmgr (web requests)
- LuaTex / LMTX (lua)
- Biber (perl)
- pdftex (for completeness)

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

# build TeX Directory Structure (TDS) and latex format file (latex.fmt)
# make tds-basic
make tds-small
# make tds-medium
# make tds-full

# build wasm tools
make wasm

# copies binaries and TexLive TDS into ./dist
make dist

# remove build and source completely
make clean
```

### Usage
```shell
# browser version, will serve index.html at http://localhost:8080
python3.8 serve.py
```

### References
1. [texlive.js](https://github.com/manuels/texlive.js/)
2. [xetex.js](https://github.com/lyze/xetex-js)
3. [dvi2html](https://github.com/kisonecat/dvi2html), [web2js](https://github.com/kisonecat/web2js)
4. [SwiftLaTeX](https://github.com/SwiftLaTeX/SwiftLaTeX)
5. [JavascriptSubtitlesOctopus](https://github.com/Dador/JavascriptSubtitlesOctopus)
6. fontconfig patch [1](https://github.com/Dador/JavascriptSubtitlesOctopus/blob/master/build/patches/fontconfig/0002-fix-fcstats-emscripten.patch) and [2](https://github.com/lyze/xetex-js/blob/master/fontconfig-fcstat.c.patch)
7. [js-sha1](https://raw.githubusercontent.com/emn178/js-sha1)

### Links
https://stackoverflow.com/questions/1114789/how-can-i-convert-perl-to-c

https://tug.org/TUGboat/tb40-1/tb124hagen-lmtx.pdf

https://github.com/Sable/emscripten_malloc

https://github.com/dmonad/pdftex.js

http://www.readytext.co.uk/?p=3590

https://github.com/skalogryz/wasmbin

https://ctan.org/tex-archive/systems/unix/tex-fpc?lang=en

https://www.tomaz.me/2014/01/08/detecting-which-process-is-creating-a-file-using-ld-preload-trick.html

http://avf.sourceforge.net/

https://arxiv.org/pdf/1908.10740.pdf

https://github.com/jacereda/fsatrace

https://github.com/fritzw/ld-preload-open/blob/master/path-mapping.c

https://adared.ch/unionfs_by_intercept/

https://gist.github.com/przemoc/571086
