# TexWaller: texlive.js on WASM

Currently compiles into a **fully static binary** (via musl on Alpine Linux):
- xetex
- pdftex
- luahbtex
- bibtex8
- xdvipdfmx
- kpsewhich, kpsestat, kpseaccess, kpsereadlink
- makeindex

### License
MIT

### Usage
```shell
# wasm version, download latest compiled assets, launch the web server example.py and then go to http://localhost:8080/example/example.html
mkdir -p dist
wget -P dist --backups=1 $(printf "https://busytex.github.io/dist/%s " busytex_pipeline.js busytex_worker.js    busytex.wasm busytex.js texlive-basic.js texlive-basic.data    ubuntu-texlive-latex-extra.data ubuntu-texlive-latex-extra.js    ubuntu-texlive-latex-recommended.data ubuntu-texlive-latex-recommended.js    ubuntu-texlive-science.data ubuntu-texlive-science.js)
python3 example/example.py
```

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
