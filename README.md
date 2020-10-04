# [WIP] TexLive 2020 compiled with Emscripten into WebAssembly and bundled into a single executable

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
git clone https://github.com/vadimkantorov/busytex
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

# Online Editor

### TODO
1. publish a pdf to github releases: https://developer.github.com/v3/repos/releases/#create-a-release, https://developer.github.com/v3/repos/releases/#upload-a-release-asset, https://developer.github.com/v3/repos/releases/#update-a-release-asset
2. Store file sha hashes in .git directory
6. arg1/arg2
7. TexLive / xetex.js
8. Ctrl+V, command history
9. Figure out Terminal sizing
10. file tab auto-complete
11. Shell into module
12. GutHub into module

### Links

https://swimburger.net/blog/dotnet/how-to-deploy-aspnet-blazor-webassembly-to-github-pages

https://github.com/tbfleming/em-shell

https://medium.com/codingtown/xterm-js-terminal-2b19ccd2a52

https://github.com/RangerMauve/xterm-js-shell

https://github.com/latexjs/latexjs/blob/master/latexjs/Dockerfile

https://github.com/latexjs/latexjs

https://github.com/emscripten-core/emscripten/issues/2040

https://git-scm.com/docs/gitrepository-layout

https://stackoverflow.com/questions/59983250/there-is-any-standalone-version-of-the-treeview-component-of-vscode

https://itnext.io/build-ffmpeg-webassembly-version-ffmpeg-js-part-3-ffmpeg-js-v0-1-0-transcoding-avi-to-mp4-f729e503a397

https://mozilla.github.io/pdf.js/examples/index.html#interactive-examples

https://github.com/AREA44/vscode-LaTeX-support

https://github.com/microsoft/monaco-languages

https://browsix.org/latex-demo-sync/

https://developer.github.com/v3/repos/contents/#create-or-update-file-contents

https://github.com/zrxiv/browserext/blob/master/backend.js

http://www.levibotelho.com/development/commit-a-file-with-the-github-api/

### Install Emscripten
```shell
# https://emscripten.org/docs/getting_started/downloads.html#installation-instructions 
git clone https://github.com/emscripten-core/emsdk.git
cd emsdk
./emsdk install latest
./emsdk activate latest
```

### Activate Emscripten
```shell
source ./emsdk_env.sh
```

### Build
```shell
make assets/test.txt assets/test.pdf
make cat.html
```

### Run
```shell
python3 serve.py

open https://localhost:8080
```

