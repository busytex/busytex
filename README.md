# TexWaller: Client-Side LaTeX to PDF Compilation on WASM

TexWaller enables **client-side LaTeX to PDF compilation** using WebAssembly (WASM).  
It compiles into a **fully static binary** (via musl on Alpine Linux), including the following tools:

- `xetex`
- `pdftex`
- `luahbtex`
- `bibtex8`
- `xdvipdfmx`
- `kpsewhich`, `kpsestat`, `kpseaccess`, `kpsereadlink`
- `makeindex`

## License
MIT

## Usage

```sh
# Download latest compiled assets and launch the web server with npx serve
mkdir -p dist
wget -P dist --backups=1 $(printf "https://busytex.github.io/dist/%s " busytex_pipeline.js busytex_worker.js    busytex.wasm busytex.js texlive-basic.js texlive-basic.data    ubuntu-texlive-latex-extra.data ubuntu-texlive-latex-extra.js    ubuntu-texlive-latex-recommended.data ubuntu-texlive-latex-recommended.js    ubuntu-texlive-science.data ubuntu-texlive-science.js)

# Serve static files using npx
npx serve public
```
Then open [http://localhost:3000](http://localhost:3000) in your browser.

Alternatively, run the Node.js server:
```sh
node src/main.js
```
Then open [http://localhost:8080](http://localhost:8080).

## Building from Source

```sh
# Install dependencies: wget, cmake, gperf, p7zip-full, emscripten
apt-get install wget cmake gperf p7zip-full 

# Set up Emscripten
git clone https://github.com/emscripten-core/emsdk
cd emsdk
./emsdk update-tags
./emsdk install tot
./emsdk activate tot
source emsdk_env.sh

# Clone busytex
git clone https://github.com/busytex/busytex
cd busytex

# Set make parallelism
export MAKEFLAGS=-j8

# Download and patch TeXLive into ./source
make texlive

# Build native tools and fonts file into ./build/native
make native

# Smoke test native binaries
make test

# Build WASM tools into ./build/wasm
make wasm

# Build TeX Directory Structure (TDS)
make tds-basic

# Test native binaries
sh scripts/build_cosmo.sh

# Reproduce and pack Ubuntu TeXLive packages into WASM data files
make build/wasm/texlive-basic.js

# Copy binaries and TeXLive TDS into ./dist
make dist-native dist-wasm

# Remove ./build and ./source completely
make clean
```

## Project Structure

```
.
├── README.md                # Project documentation
├── package.json             # Node.js package dependencies
├── package-lock.json        # Lockfile for dependencies
├── Makefile                 # Build automation script
├── dist/                    # Compiled assets
├── public/                  # Static files for web serving
│   ├── index.html           # Main entry point for frontend
│   ├── assets/              # Images and other assets
│   ├── styles.css           # Stylesheets (if applicable)
│   ├── script.js            # Frontend scripts (if applicable)
├── src/                     # Node.js backend
│   ├── main.js              # Main server script
├── scripts/                 # Build and utility scripts
│   ├── build_arxiv.sh
│   ├── build_arxiv.ps1
│   ├── build_arxiv_strace.sh
│   ├── build_cosmo.sh
├── legacy/                  # Old or deprecated files
│   ├── busytex.c
│   ├── busytexmk.py
│   ├── cosmo_getpass.h
│   ├── emcc_wrapper.py
│   ├── log_file_access_dynamic.c
│   ├── packfs.c
│   ├── packfs.py
│   ├── ubuntu_package_preload.py
```

## References
- [pdftex.js](https://github.com/dmonad/pdftex.js)
- [xetex.js](https://github.com/lyze/xetex-js)
- [texlive.js](https://github.com/manuels/texlive.js/)
- [latexjs](https://github.com/latexjs/latexjs)
- [dvi2html](https://github.com/kisonecat/dvi2html)
- [web2js](https://github.com/kisonecat/web2js)
- [SwiftLaTeX](https://github.com/SwiftLaTeX/SwiftLaTeX)
- [JavascriptSubtitlesOctopus](https://github.com/Dador/JavascriptSubtitlesOctopus)
- [js-sha1](https://raw.githubusercontent.com/emn178/js-sha1)
- [BLFS](http://www.linuxfromscratch.org/blfs/view/svn/pst/texlive.html)
- [Latexmk](https://github.com/schlamar/latexmk.py)