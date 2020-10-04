#TODO: caching for cloning
#TODO: rate limit error: documentation_url: "https://docs.github.com/rest/overview/resources-in-the-rest-api#rate-limiting"
#TODO: message: "API rate limit exceeded for 92.169.44.67. (But here's the good news: Authenticated requests get a higher rate limit. Check out the documentation for more details.)"
#TODO: https://microsoft.github.io/monaco-editor/playground.html#interacting-with-the-editor-adding-an-action-to-an-editor-instance
#TODO: https://microsoft.github.io/monaco-editor/playground.html#extending-language-services-custom-languages

#TODO: native busytex: + CSFINPUT/fontconfig.conf//'--csfile', '/bibtex/88591lat.csf'
#TODO: abspath/realpath instead of ROOT
#TODO: location of hyphen.cfg file? https://tex.loria.fr/ctan-doc/macros/latex/doc/html/cfgguide/node11.html
# https://github.com/libgit2/libgit2/blob/96a5f38f51bc53895000787542f92d0a3352c026/src/merge_file.c
# https://github.com/git/git/blob/master/xdiff/xdiff.h
# do not pass .pdf and .log to compiler


#TODO: custom binaries for install-tl
#TODO: enable tlmgr customization
#TODO: instruction for local tlmgr install tinytex
#TODO: install-tl install from local full download

#TODO: custom FS that could work with package zip archvies (CTAN? ftp://tug.org/texlive/Contents/live/texmf-dist/)
#TODO: https://github.com/emscripten-core/emscripten/issues/11709#issuecomment-663901019
# https://github.com/emscripten-core/emscripten/blob/master/src/library_idbfs.js#L21
# https://en.wikibooks.org/wiki/LaTeX/Installing_Extra_Packages
# https://github.com/emscripten-core/emscripten/pull/4737

# https://ctan.crest.fr/tex-archive/macros/latex/contrib/
# ftp://tug.org/texlive/Contents/live/texmf-dist/
# http://tug.org/texmf-dist/

# $@ is lhs
# $< is rhs
# $* is captured % (pattern)

URL_UBUNTU_RELEASE = https://packages.ubuntu.com/groovy/
URL_git = https://mirrors.edge.kernel.org/pub/software/scm/git/git-2.28.0.tar.gz

URL_texlive = https://github.com/TeX-Live/texlive-source/archive/9ed922e7d25e41b066f9e6c973581a4e61ac0328.tar.gz
URL_expat = https://github.com/libexpat/libexpat/releases/download/R_2_2_9/expat-2.2.9.tar.gz
URL_fontconfig = https://www.freedesktop.org/software/fontconfig/release/fontconfig-2.13.92.tar.gz

URL_TEXLIVE_TEXMF = ftp://tug.org/texlive/historic/2020/texlive-20200406-texmf.tar.xz 
URL_TEXLIVE_INSTALLER = http://mirror.ctan.org/systems/texlive/tlnet/install-tl-unx.tar.gz
URL_TEXLIVE_TLPDB = ftp://tug.org/texlive/historic/2020/texlive-20200406-tlpdb-full.tar.gz

ROOT := $(CURDIR)
EMROOT := $(dir $(shell which emcc))
PYTHON = python3

TEXLIVE_BUILD_DIR=$(ROOT)/build/wasm/texlive
WEB2C_NATIVE_TOOLS_DIR=$(ROOT)/build/native/texlive/texk/web2c
FONTCONFIG_BUILD_DIR=$(ROOT)/build/wasm/fontconfig
EXPAT_BUILD_DIR=$(ROOT)/build/wasm/expat

PREFIX_wasm = $(ROOT)/build/wasm/prefix
PREFIX_native = $(ROOT)/build/native/prefix

MAKE_wasm = emmake make
CMAKE_wasm = emcmake cmake
CONFIGURE_wasm = emconfigure
AR_wasm = emar
MAKE_native = make
CMAKE_native = cmake
AR_native = $(AR)

TOTAL_MEMORY = 536870912
SKIP = all install:

CACHE_native_texlive = $(ROOT)/build/native-texlive.cache
CACHE_wasm_texlive = $(ROOT)/build/wasm-texlive.cache
CACHE_native_fontconfig = $(ROOT)/build/native-fontconfig.cache
CACHE_wasm_fontconfig = $(ROOT)/build/wasm-fontconfig.cache
CONFIGSITE_BUSYTEX = $(ROOT)/busytex.site

CFLAGS_native_OPT = -O3
CFLAGS_wasm_OPT = -Oz
CFLAGS_XDVIPDFMX = -Dmain='__attribute__((visibility(\"default\"))) busymain_xdvipdfmx' -Dcheck_for_jpeg=dvipdfmx_check_for_jpeg -Dcheck_for_bmp=dvipdfmx_check_for_bmp -Dcheck_for_png=dvipdfmx_check_for_png -Dseek_absolute=dvidpfmx_seek_absolute -Dseek_relative=dvidpfmx_seek_relative -Dseek_end=dvidpfmx_seek_end -Dtell_position=dvidpfmx_tell_position -Dfile_size=dvidpfmx_file_size -Dmfgets=dvipdfmx_mfgets -Dwork_buffer=dvipdfmx_work_buffer -Dget_unsigned_byte=dvipdfmx_get_unsigned_byte -Dget_unsigned_pair=dvipdfmx_get_unsigned_pair 
CFLAGS_BIBTEX = -Dmain='__attribute__((visibility(\"default\"))) busymain_bibtex8' -Dinitialize=bibtex_initialize -Deoln=bibtex_eoln -Dlast=bibtex_last -Dhistory=bibtex_history -Dbad=bibtex_bad -Dxchr=bibtex_xchr -Dbuffer=bibtex_buffer -Dclose_file=bibtex_close_file -Dusage=bibtex_usage 
CFLAGS_XETEX = -Dmain='__attribute__((visibility(\"default\"))) busymain_xetex'
CFLAGS_XDVIPDFMX_wasm = $(CFLAGS_XDVIPDFMX) $(CFLAGS_wasm_OPT)
CFLAGS_BIBTEX_wasm = $(CFLAGS_BIBTEX) $(CFLAGS_wasm_OPT)
CFLAGS_XETEX_wasm = $(CFLAGS_XETEX) $(CFLAGS_wasm_OPT)
CFLAGS_XDVIPDFMX_native = $(CFLAGS_XDVIPDFMX) $(CFLAGS_native_OPT)
CFLAGS_BIBTEX_native = $(CFLAGS_BIBTEX) $(CFLAGS_native_OPT)
CFLAGS_XETEX_native = $(CFLAGS_XETEX) $(CFLAGS_native_OPT)

CFLAGS_wasm_bibtex = -s TOTAL_MEMORY=$(TOTAL_MEMORY) $(CFLAGS_wasm_OPT)
CFLAGS_wasm_texlive = -s ERROR_ON_UNDEFINED_SYMBOLS=0 -I$(ROOT)/build/wasm/texlive/libs/icu/include -I$(ROOT)/source/fontconfig $(CFLAGS_wasm_OPT) 
CFLAGS_wasm_icu = -s ERROR_ON_UNDEFINED_SYMBOLS=0 $(CFLAGS_wasm_OPT)
# uuid_generate_random feature request: https://github.com/emscripten-core/emscripten/issues/12093
CFLAGS_wasm_fontconfig = -Duuid_generate_random=uuid_generate $(CFLAGS_wasm_OPT)
CFLAGS_wasm_fontconfig_FREETYPE = $(addprefix -I$(ROOT)/build/wasm/texlive/libs/, freetype2/ freetype2/freetype2/) -
LIBS_wasm_fontconfig_FREETYPE = -L$(ROOT)/build/wasm/texlive/libs/freetype2/ -lfreetype
PKGDATAFLAGS_wasm_icu = --without-assembly -O $(ROOT)/build/wasm/texlive/libs/icu/icu-build/data/icupkg.inc

CFLAGS_native_texlive = -I$(ROOT)/build/native/texlive/libs/icu/include -I$(ROOT)/source/fontconfig
CFLAGS_native_fontconfig_FREETYPE = $(addprefix -I$(ROOT)/build/native/texlive/libs/, freetype2/ freetype2/freetype2/)
LIBS_native_fontconfig_FREETYPE = -L$(ROOT)/build/native/texlive/libs/freetype2/ -lfreetype

# EM_COMPILER_WRAPPER / EM_COMPILER_LAUNCHER feature request: https://github.com/emscripten-core/emscripten/issues/12340
CCSKIP_wasm_icu = $(PYTHON) $(ROOT)/busytex_emcc_wrapper.py $(addprefix $(ROOT)/build/native/texlive/libs/icu/icu-build/bin/, icupkg pkgdata) --
CCSKIP_wasm_freetype2 = $(PYTHON) $(ROOT)/busytex_emcc_wrapper.py $(ROOT)/build/native/texlive/libs/freetype2/ft-build/apinames --
CCSKIP_wasm_xetex = $(PYTHON) $(ROOT)/busytex_emcc_wrapper.py $(addprefix $(ROOT)/build/native/texlive/texk/web2c/, ctangle otangle tangle tangleboot ctangleboot tie xetex) $(addprefix $(ROOT)/build/native/texlive/texk/web2c/web2c/, fixwrites makecpool splitup web2c) --
OPTS_wasm_icu_configure = CC="$(CCSKIP_wasm_icu) emcc $(CFLAGS_wasm_icu)" CXX="$(CCSKIP_wasm_icu) em++ $(CFLAGS_wasm_icu)"
OPTS_wasm_icu_make = -e PKGDATA_OPTS="$(PKGDATAFLAGS_wasm_icu)" -e CC="$(CCSKIP_wasm_icu) emcc $(CFLAGS_wasm_icu)" -e CXX="$(CCSKIP_wasm_icu) em++ $(CFLAGS_wasm_icu)"
OPTS_wasm_bibtex = -e CFLAGS="$(CFLAGS_BIBTEX_wasm) $(CFLAGS_wasm_bibtex)" -e CXXFLAGS="$(CFLAGS_BIBTEX_wasm) $(CFLAGS_wasm_bibtex)"
OPTS_wasm_freetype2 = CC="$(CCSKIP_wasm_freetype2) emcc"
OPTS_wasm_xetex = CC="$(CCSKIP_wasm_xetex) emcc $(CFLAGS_XETEX_wasm)" CXX="$(CCSKIP_wasm_xetex) em++ $(CFLAGS_XETEX_wasm)"
OPTS_wasm_xdvipdfmx= CC="emcc $(CFLAGS_XDVIPDFMX_wasm)" CXX="em++ $(CFLAGS_XDVIPDFMX_wasm)"

OPTS_native_xdvipdfmx= -e CFLAGS="$(CFLAGS_native_texlive) $(CFLAGS_XDVIPDFMX_native)" -e CPPFLAGS="$(CFLAGS_native_texlive) $(CFLAGS_XDVIPDFMX_native)"
OPTS_native_bibtex = -e CFLAGS="$(CFLAGS_BIBTEX_native) $(CFLAGS_native_bibtex)" -e CXXFLAGS="$(CFLAGS_BIBTEX_native) $(CFLAGS_wasm_native)"
OPTS_native_xetex = CC="$(CC) $(CFLAGS_XETEX_native)" CXX="$(CXX) $(CFLAGS_XETEX_native)"

OBJ_XETEX = synctexdir/xetex-synctex.o xetex-xetexini.o xetex-xetex0.o xetex-xetex-pool.o xetexdir/xetex-xetexextra.o lib/lib.a libmd5.a libxetex.a
OBJ_DVIPDF = texlive/texk/dvipdfm-x/xdvipdfmx.a
OBJ_BIBTEX = texlive/texk/bibtex-x/bibtex8.a

#texlive/libs/icu/icu-build/lib/libicuio.a texlive/libs/icu/icu-build/lib/libicui18n.a 
OBJ_DEPS = texlive/libs/harfbuzz/libharfbuzz.a texlive/libs/graphite2/libgraphite2.a texlive/libs/teckit/libTECkit.a texlive/libs/libpng/libpng.a  fontconfig/src/.libs/libfontconfig.a texlive/libs/freetype2/libfreetype.a texlive/libs/pplib/libpplib.a texlive/libs/zlib/libz.a texlive/libs/libpaper/libpaper.a texlive/libs/icu/icu-build/lib/libicuuc.a texlive/libs/icu/icu-build/lib/libicudata.a texlive/texk/kpathsea/.libs/libkpathsea.a expat/libexpat.a 
INCLUDE_DEPS = texlive/libs/icu/include fontconfig

.PHONY: all
all:
	make texlive
	make native
	make tds
	make wasm

source/texlive.downloaded source/expat.downloaded source/fontconfig.downloaded :
	mkdir -p $(basename $@)
	wget --no-clobber $(URL_$(notdir $(basename $@))) -O "$(basename $@).tar.gz" || true
	tar -xf "$(basename $@).tar.gz" --strip-components=1 --directory="$(basename $@)"
	touch $@

source/fontconfig.patched: source/fontconfig.downloaded
	patch -d $(basename $<) -Np1 -i $(ROOT)/fontconfig_emcc.patch
	echo "$(SKIP)" > source/fontconfig/test/Makefile.in 
	touch $@

source/texlive.patched: source/texlive.downloaded
	rm -rf $(addprefix source/texlive/, texk/upmendex texk/dviout-util texk/dvipsk texk/xdvik texk/dviljk texk/dvipos texk/dvidvi texk/dvipng texk/dvi2tty texk/dvisvgm texk/dtl texk/gregorio texk/cjkutils texk/musixtnt texk/tests texk/ttf2pk2 texk/ttfdump texk/makejvf texk/lcdf-typetools) || true
	touch $@

build/%/texlive.configured: source/texlive.patched
	mkdir -p $(basename $@)
	echo '' > $(CACHE_$*_texlive)
	cd $(basename $@) &&                        \
	CONFIG_SITE=$(CONFIGSITE_BUSYTEX) $(CONFIGURE_$*) $(ROOT)/source/texlive/configure		\
	  --cache-file=$(CACHE_$*_texlive)  		\
	  --prefix="$(PREFIX_$*)"					\
	  --enable-dump-share						\
	  --enable-static							\
	  --enable-freetype2						\
	  --disable-shared							\
	  --disable-multiplatform					\
	  --disable-native-texlive-build			\
	  --disable-all-pkgs						\
	  --without-x								\
	  --without-system-cairo					\
	  --without-system-gmp						\
	  --without-system-graphite2				\
	  --without-system-harfbuzz					\
	  --without-system-libgs					\
	  --without-system-libpaper					\
	  --without-system-mpfr						\
	  --without-system-pixman					\
	  --without-system-poppler					\
	  --without-system-xpdf						\
	  --without-system-icu						\
	  --without-system-fontconfig				\
	  --without-system-freetype2				\
	  --without-system-libpng					\
	  --without-system-zlib						\
	  --with-banner-add="_busytex$*"			\
		CFLAGS="$(CFLAGS_$*_texlive)"	     	\
	  CPPFLAGS="$(CFLAGS_$*_texlive)"           \
	  CXXFLAGS="$(CFLAGS_$*_texlive)"
	$(MAKE_$*) -C $(basename $@)
	touch $@

build/wasm/texlive/libs/icu/icu-build/lib/libicuuc.a : build/wasm/texlive.configured build/native/texlive/libs/icu/icu-build/bin/icupkg build/native/texlive/libs/icu/icu-build/bin/pkgdata
	cd build/wasm/texlive/libs/icu && \
	$(CONFIGURE_wasm) $(ROOT)/source/texlive/libs/icu/configure $(OPTS_wasm_icu_configure)
	$(MAKE_wasm) -C build/wasm/texlive/libs/icu $(OPTS_wasm_icu_make) 
	echo "$(SKIP)" > build/wasm/texlive/libs/icu/icu-build/test/Makefile
	$(MAKE_wasm) -C build/wasm/texlive/libs/icu/icu-build $(OPTS_wasm_icu_make) 

build/native/texlive/libs/icu/icu-build/lib/libicuuc.a build/native/texlive/libs/icu/icu-build/lib/libicudata.a build/native/texlive/libs/icu/icu-build/bin/icupkg build/native/texlive/libs/icu/icu-build/bin/pkgdata : build/native/texlive.configured
	$(MAKE_native) -C build/native/texlive/libs/icu 
	$(MAKE_native) -C build/native/texlive/libs/icu/icu-build 

build/wasm/texlive/libs/freetype2/libfreetype.a: build/wasm/texlive.configured build/native/texlive/libs/freetype2/libfreetype.a
	$(MAKE_wasm) -C $(dir $@) $(OPTS_wasm_freetype2)

build/%/texlive/libs/teckit/libTECkit.a build/%/texlive/libs/harfbuzz/libharfbuzz.a build/%/texlive/libs/graphite2/libgraphite2.a build/%/texlive/libs/libpng/libpng.a build/%/texlive/libs/libpaper/libpaper.a build/%/texlive/libs/zlib/libz.a build/%/texlive/libs/pplib/libpplib.a build/%/texlive/libs/freetype2/libfreetype.a: build/%/texlive build/%/texlive.configured
	$(MAKE_$*) -C $(dir $@)  

build/%/expat/libexpat.a: source/expat.downloaded
	mkdir -p $(dir $@) && cd $(dir $@) && \
	$(CMAKE_$*) \
	   -DCMAKE_C_FLAGS="$(CFLAGS_$*_OPT)" \
	   -DEXPAT_BUILD_DOCS=off \
	   -DEXPAT_SHARED_LIBS=off \
	   -DEXPAT_BUILD_EXAMPLES=off \
	   -DEXPAT_BUILD_FUZZERS=off \
	   -DEXPAT_BUILD_TESTS=off \
	   -DEXPAT_BUILD_TOOLS=off \
	   $(ROOT)/$(basename $<) 
	$(MAKE_$*) -C $(dir $@)

build/%/fontconfig/src/.libs/libfontconfig.a: source/fontconfig.patched build/%/expat/libexpat.a build/%/texlive/libs/freetype2/libfreetype.a
	echo '' > $(CACHE_$*_fontconfig)
	mkdir -p build/$*/fontconfig
	cd build/$*/fontconfig && \
	$(CONFIGURE_$*) $(ROOT)/$(basename $<)/configure \
	   --cache-file=$(CACHE_$*_fontconfig)		 \
	   --prefix=$(PREFIX_$*) \
	   --enable-static \
	   --disable-shared \
	   --disable-docs \
	   --with-expat-includes="$(ROOT)/source/expat/lib" \
	   --with-expat-lib="$(ROOT)/build/$*/expat" \
	   CFLAGS="$(CFLAGS_$*_fontconfig) $(CFLAGS_$*_OPT)" FREETYPE_CFLAGS="$(CFLAGS_$*_fontconfig_FREETYPE)" FREETYPE_LIBS="$(LIBS_$*_fontconfig_FREETYPE)"
	$(MAKE_$*) -C build/$*/fontconfig

################################################################################################################

build/native/texlive/texk/dvipdfm-x/xdvipdfmx.a: build/native/texlive.configured
	$(MAKE_native) -C $(dir $@) $(subst -Dmain, -Dbusymain, $(OPTS_native_xdvipdfmx))
	rm $(dir $@)/dvipdfmx.o
	$(MAKE_native) -C $(dir $@) dvipdfmx.o $(OPTS_native_xdvipdfmx)
	$(AR_native) -crs $@ $(dir $@)/*.o

build/native/texlive/texk/bibtex-x/bibtex8.a: build/native/texlive.configured
	$(MAKE_native) -C $(dir $@) CSFINPUT=/bibtex $(subst -Dmain, -Dbusymain, $(OPTS_native_bibtex))
	rm $(dir $@)/bibtex8-bibtex.o
	$(MAKE_native) -C $(dir $@) bibtex8-bibtex.o $(OPTS_native_bibtex)
	$(AR_native) -crs $@ $(dir $@)/bibtex8-*.o

build/native/texlive/texk/web2c/libxetex.a: build/native/texlive.configured
	$(MAKE_native) -C $(dir $@) clean
	$(MAKE_native) -C $(dir $@) synctexdir/xetex-synctex.o xetex $(subst -Dmain, -Dbusymain, $(OPTS_native_xetex))
	rm $(dir $@)/xetexdir/xetex-xetexextra.o
	$(MAKE_native) -C $(dir $@) xetexdir/xetex-xetexextra.o $(OPTS_native_xetex)
	$(MAKE_native) -C $(dir $@) libxetex.a $(OPTS_native_xetex)

.PHONY: build/native/busytex
build/native/busytex: 
	mkdir -p $(dir $@)
	$(CC) -c busytex.c -o busytex.o
	$(CXX)  $(CFLAGS_native_OPT) -o $@ -lm -pthread busytex.o $(addprefix build/native/texlive/texk/web2c/, $(OBJ_XETEX)) $(addprefix build/native/, $(OBJ_DVIPDF) $(OBJ_BIBTEX) $(OBJ_DEPS)) $(addprefix -Ibuild/native/, $(INCLUDE_DEPS)) 

#build/native/texlive/texk/web2c/xetex: 
#	$(MAKE_native) -C $(dir $@) xetex 

################################################################################################################

build/wasm/texlive/texk/dvipdfm-x/xdvipdfmx.a: build/wasm/texlive.configured
	$(MAKE_wasm) -C $(dir $@) $(OPTS_wasm_xdvipdfmx)
	$(AR_wasm) -crs $@ $(dir $@)/*.o

build/wasm/texlive/texk/bibtex-x/bibtex8.a: build/wasm/texlive.configured
	$(MAKE_wasm) -C $(dir $@) CSFINPUT=/bibtex $(OPTS_wasm_bibtex)
	$(AR_wasm) -crs $@ $(dir $@)/bibtex8-*.o

build/wasm/texlive/texk/web2c/libxetex.a: build/wasm/texlive.configured
	# copying generated C files from native version, since string offsets are off
	mkdir -p build/wasm/texlive/texk/web2c
	cp build/native/texlive/texk/web2c/*.c build/wasm/texlive/texk/web2c
	$(MAKE_wasm) -C $(dir $@) synctexdir/xetex-synctex.o xetex $(OPTS_wasm_xetex)


################################################################################################################

build/install-tl/install-tl:
	mkdir -p $(dir $@)
	wget --no-clobber $(URL_TEXLIVE_INSTALLER) -P source || true
	tar -xf "source/$(notdir $(URL_TEXLIVE_INSTALLER))" --strip-components=1 --directory="$(dir $@)"

build/wasm/fontconfig.conf:
	mkdir -p $(dir $@)
	echo '<?xml version="1.0"?>' > $@
	echo '<!DOCTYPE fontconfig SYSTEM "fonts.dtd">' >> $@
	echo '<fontconfig>' >> $@
	echo '<dir>/texlive/texmf-dist/fonts/opentype</dir>' >> $@
	echo '<dir>/texlive/texmf-dist/fonts/type1</dir>' >> $@
	echo '</fontconfig>' >> $@

build/texlive-%.profile:
	mkdir -p $(dir $@)
	echo selected_scheme scheme-$* > $@
	echo TEXDIR $(ROOT)/$(basename $@) >> $@
	echo TEXMFLOCAL $(ROOT)/$(basename $@)/texmf-local >> $@
	echo TEXMFSYSVAR $(ROOT)/$(basename $@)/texmf-var >> $@
	echo TEXMFSYSCONFIG $(ROOT)/$(basename $@)/texmf-config >> $@
	echo TEXMFVAR $(ROOT)/$(basename $@)/home/texmf-var >> $@

build/texlive-%/texmf-dist: build/install-tl/install-tl build/texlive-%.profile
	# https://www.tug.org/texlive/doc/install-tl.html
	#TODO: find texlive-$*/ -executable -type f -exec rm {} +
	mkdir -p $(dir $@)
	TEXLIVE_INSTALL_NO_RESUME=1 $< -profile build/texlive-$*.profile
	rm -rf $(addprefix $(dir $@)/, bin readme* tlpkg install* *.html texmf-dist/doc texmf-var/doc texmf-var/web2c readme-html.dir readme-txt.dir) || true

build/format-%/latex.fmt: build/native/busytex build/texlive-%/texmf-dist 
	mkdir -p $(dir $@)
	rm $(dir $@)/* || true
	TEXINPUTS=build/texlive-basic/texmf-dist/source/latex/base TEXMFCNF=build/texlive-$*/texmf-dist/web2c TEXMFDIST=build/texlive-$*/texmf-dist $< xetex -interaction=nonstopmode -output-directory=$(dir $@) -kpathsea-debug=32 -ini -etex unpack.ins
	TEXINPUTS=build/texlive-basic/texmf-dist/source/latex/base:build/texlive-basic/texmf-dist/tex/generic/unicode-data:build/texlive-basic/texmf-dist/tex/latex/base:build/texlive-basic/texmf-dist/tex/generic/hyphen/ TEXMFCNF=build/texlive-$*/texmf-dist/web2c TEXMFDIST=build/texlive-$*/texmf-dist $< xetex -interaction=nonstopmode -output-directory=$(dir $@) -kpathsea-debug=32 -ini -etex latex.ltx

build/wasm/texlive-%.js: build/format-%/latex.fmt build/texlive-%/texmf-dist build/wasm/fontconfig.conf 
	#https://github.com/emscripten-core/emscripten/issues/12214
	mkdir -p $(dir $@)
	echo > build/empty
	$(PYTHON) $(EMROOT)/tools/file_packager.py $(basename $@).data --js-output=$@ --export-name=BusytexDataLoader \
		--lz4 --use-preload-cache \
		--preload build/empty@/bin/busytex \
		--preload build/wasm/fontconfig.conf@/fontconfig/texlive.conf \
		--preload build//texlive-$*/texmf-dist/web2c/texmf.cnf@/texmf.cnf \
		--preload build/texlive-$*@/texlive \
		--preload build/format-$*/latex.fmt@/latex.fmt \
		--preload source/texlive/texk/bibtex-x/csf@/bibtex

.PHONY: dist/texlive-lazy.js
dist/texlive-lazy.js:
	mkdir -p $(dir $@)
	rm -rf dist/texmf || true
	$(PYTHON) lazy_packager.py dist --js-output=$@ --export-name=BusytexDataLoader \
		--preload build/texlive-full/texmf-dist/tex/latex/titlesec@/texmf/texmf-dist/tex/latex/titlesec \
		--preload build/texlive-full/texmf-dist/tex/latex/xcolor@/texmf/texmf-dist/tex/latex/xcolor \
		--preload build/texlive-full/texmf-dist/tex/latex/etoolbox@/texmf/texmf-dist/tex/latex/etoolbox \
		--preload build/texlive-full/texmf-dist/tex/latex/footmisc@/texmf/texmf-dist/tex/latex/footmisc \
		--preload build/texlive-full/texmf-dist/tex/latex/textpos@/texmf/texmf-dist/tex/latex/textpos \
		--preload build/texlive-full/texmf-dist/tex/latex/ms@/texmf/texmf-dist/tex/latex/ms \
		--preload build/texlive-full/texmf-dist/tex/latex/parskip@/texmf/texmf-dist/tex/latex/parksip

build/wasm/texlive-latex-%.js:
	mkdir -p $(dir $@)
	$(PYTHON) $(EMROOT)/tools/file_packager.py $(basename $@).data --js-output=$@ --export-name=BusytexDataLoader \
		--lz4 --use-preload-cache \
		$(shell $(PYTHON) ubuntu_package_preload.py --texmf build/texlive-full --url $(URL_UBUNTU_RELEASE) --package texlive-latex-$*)

################################################################################################################

.PHONY:build/wasm/busytex.js
build/wasm/busytex.js: 
	mkdir -p $(dir $@)
	emcc $(CFLAGS_OPT) -s TOTAL_MEMORY=$(TOTAL_MEMORY) -s EXIT_RUNTIME=0 -s INVOKE_RUN=0  -s ASSERTIONS=1 -s ERROR_ON_UNDEFINED_SYMBOLS=0 -s FORCE_FILESYSTEM=1 -s LZ4=1 -s MODULARIZE=1 -s EXPORT_NAME=$(notdir $(basename $@)) -s EXPORTED_FUNCTIONS='["_main"]' -s EXPORTED_RUNTIME_METHODS='["callMain","FS", "ENV", "allocateUTF8OnStack", "LZ4", "PROXYFS", "PATH"]' -lproxyfs.js  -o $@ -lm $(addprefix build/wasm/texlive/texk/web2c/, $(OBJ_XETEX)) $(addprefix build/wasm/, $(OBJ_DVIPDF) $(OBJ_BIBTEX) $(OBJ_DEPS)) $(addprefix -Ibuild/wasm/, $(INCLUDE_DEPS)) busytex.c

################################################################################################################

.PHONY: texlive
texlive:
	make source/texlive.downloaded
	make source/texlive.patched

.PHONY: native
native: 
	make build/native/texlive.configured
	make build/native/texlive/libs/libpng/libpng.a 
	make build/native/texlive/libs/libpaper/libpaper.a 
	make build/native/texlive/libs/zlib/libz.a 
	make build/native/texlive/libs/teckit/libTECkit.a 
	make build/native/texlive/libs/harfbuzz/libharfbuzz.a 
	make build/native/texlive/libs/graphite2/libgraphite2.a 
	make build/native/texlive/libs/pplib/libpplib.a 
	make build/native/texlive/libs/freetype2/libfreetype.a 
	make build/native/texlive/libs/icu/icu-build/lib/libicuuc.a 
	make build/native/texlive/libs/icu/icu-build/lib/libicudata.a
	make build/native/texlive/libs/icu/icu-build/bin/icupkg 
	make build/native/texlive/libs/icu/icu-build/bin/pkgdata 
	make build/native/expat/libexpat.a
	make build/native/fontconfig/src/.libs/libfontconfig.a
	# regular binaries 
	make build/native/texlive/texk/bibtex-x/bibtex8.a
	make build/native/texlive/texk/dvipdfm-x/xdvipdfmx.a
	make build/native/texlive/texk/web2c/libxetex.a
	make build/native/busytex

#.PHONY: tds-basic tds-small tds-full
tds-%:
	make build/install-tl/install-tl
	make build/texlive-$*.profile
	make build/texlive-$*/texmf-dist
	make build/format-$*/latex.fmt
	make build/wasm/fontconfig.conf

.PHONY: tds
tds:
	make tds-basic
	make tds-small
	make tds-medium
	make build/wasm/
	# make tds-full

.PHONY: tds-wasm
tds-wasm:
	#make build/wasm/texlive-basic.js
	#make build/wasm/texlive-small.js
	#make build/wasm/texlive-medium.js
	make build/wasm/texlive-latex-recommended.js
	make build/wasm/texlive-latex-extra.js

.PHONY: wasm
wasm:
	make build/wasm/texlive.configured
	make build/wasm/texlive/libs/libpng/libpng.a 
	make build/wasm/texlive/libs/libpaper/libpaper.a 
	make build/wasm/texlive/libs/zlib/libz.a 
	make build/wasm/texlive/libs/teckit/libTECkit.a 
	make build/wasm/texlive/libs/harfbuzz/libharfbuzz.a 
	make build/wasm/texlive/libs/graphite2/libgraphite2.a 
	make build/wasm/texlive/libs/pplib/libpplib.a 
	make build/wasm/texlive/libs/freetype2/libfreetype.a 
	make build/wasm/texlive/libs/icu/icu-build/lib/libicuuc.a 
	make build/wasm/texlive/libs/icu/icu-build/lib/libicudata.a
	make build/wasm/expat/libexpat.a
	make build/wasm/fontconfig/src/.libs/libfontconfig.a
	# busy binaries
	make build/wasm/texlive/texk/bibtex-x/bibtex8.a
	make build/wasm/texlive/texk/dvipdfm-x/xdvipdfmx.a
	make build/wasm/texlive/texk/web2c/libxetex.a
	make build/wasm/busytex.js

.PHONY: example
example:
	mkdir -p example/assets/large
	echo "console.log('Hello world now')" > example/assets/test.txt
	wget --no-clobber -O example/assets/test.png https://www.google.fr/images/branding/googlelogo/1x/googlelogo_color_272x92dp.png
	wget --no-clobber -O example/assets/test.svg https://upload.wikimedia.org/wikipedia/commons/c/c3/Flag_of_France.svg
	wget --no-clobber -O example/assets/large/test.pdf https://raw.githubusercontent.com/mozilla/pdf.js/ba2edeae/web/compressed.tracemonkey-pldi-09.pdf

.PHONY: clean_tds
clean_tds:
	rm -rf build/texlive-*

.PHONY: clean_native
clean_native:
	rm -rf build/native

.PHONY: clean_wasm
clean_wasm:
	rm -rf build/wasm

.PHONY: clean_format
clean_format:
	rm -rf build/format-*

.PHONY: clean_dist
clean_dist:
	rm -rf dist

.PHONY: clean
clean:
	rm -rf build source

.PHONY: dist
dist:
	mkdir -p $@
	cp build/wasm/busytex.js build/wasm/busytex.wasm $@
	#cp build/wasm/texlive-*.js build/wasm/texlive-*.data $@
	cp build/wasm/texlive-basic.js build/wasm/texlive-basic.data $@

	#cp build/native/busytex dist
	#cp -r build/native/busytex build/texlive build/texmf.cnf build/fontconfig $@

