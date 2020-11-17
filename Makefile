#TODO: replace install-tl by tlmgr

URL_texlive = https://github.com/TeX-Live/texlive-source/archive/9ed922e7d25e41b066f9e6c973581a4e61ac0328.tar.gz
URL_expat = https://github.com/libexpat/libexpat/releases/download/R_2_2_9/expat-2.2.9.tar.gz
URL_fontconfig = https://www.freedesktop.org/software/fontconfig/release/fontconfig-2.13.92.tar.gz
URL_TEXLIVE_INSTALLER = http://mirror.ctan.org/systems/texlive/tlnet/install-tl-unx.tar.gz

URL_UBUNTU_RELEASE = https://packages.ubuntu.com/groovy/

ROOT := $(CURDIR)
EMROOT := $(dir $(shell which emcc))
PYTHON = python3

XETEX = $(ROOT)/build/native/busytex xetex

TEXMF_FULL = $(ROOT)/build/texlive-full
#TEXMF_FULL = $(ROOT)/source/texlive-20200406-texmf

TEXLIVE_BUILD_DIR = $(ROOT)/build/wasm/texlive
WEB2C_NATIVE_TOOLS_DIR = $(ROOT)/build/native/texlive/texk/web2c
FONTCONFIG_BUILD_DIR = $(ROOT)/build/wasm/fontconfig
EXPAT_BUILD_DIR = $(ROOT)/build/wasm/expat

PREFIX_wasm = $(ROOT)/build/wasm/prefix
PREFIX_native = $(ROOT)/build/native/prefix

MAKE_wasm = emmake $(MAKE)
CMAKE_wasm = emcmake cmake
CONFIGURE_wasm = emconfigure
AR_wasm = emar
MAKE_native = $(MAKE)
CMAKE_native = cmake
AR_native = $(AR)

TOTAL_MEMORY = 536870912
SKIP = all install:

CACHE_TEXLIVE_native = $(ROOT)/build/native-texlive.cache
CACHE_TEXLIVE_wasm = $(ROOT)/build/wasm-texlive.cache
CACHE_FONTCONFIG_native = $(ROOT)/build/native-fontconfig.cache
CACHE_FONTCONFIG_wasm = $(ROOT)/build/wasm-fontconfig.cache
CONFIGSITE_BUSYTEX = $(ROOT)/busytex.site

CPATH_BUSYTEX = texlive/libs/icu/include fontconfig

CFLAGS_OPT_native = -O3
CFLAGS_OPT_wasm = -Oz

##############################################################################################################################

# OBJECT FILES
OBJ_XETEX = synctexdir/xetex-synctex.o xetex-xetexini.o xetex-xetex0.o xetex-xetex-pool.o xetexdir/xetex-xetexextra.o lib/lib.a libmd5.a libxetex.a
OBJ_DVIPDF = texlive/texk/dvipdfm-x/xdvipdfmx.a
OBJ_BIBTEX = texlive/texk/bibtex-x/bibtex8.a
OBJ_KPATHSEA = kpsewhich.o .libs/libkpathsea.a
#texlive/libs/icu/icu-build/lib/libicuio.a texlive/libs/icu/icu-build/lib/libicui18n.a 
OBJ_DEPS = texlive/libs/harfbuzz/libharfbuzz.a texlive/libs/graphite2/libgraphite2.a texlive/libs/teckit/libTECkit.a texlive/libs/libpng/libpng.a  fontconfig/src/.libs/libfontconfig.a texlive/libs/freetype2/libfreetype.a texlive/libs/pplib/libpplib.a texlive/libs/zlib/libz.a texlive/libs/libpaper/libpaper.a texlive/libs/icu/icu-build/lib/libicuuc.a texlive/libs/icu/icu-build/lib/libicudata.a texlive/texk/kpathsea/.libs/libkpathsea.a expat/libexpat.a 

##############################################################################################################################

# TOOLS CFLAGS
CFLAGS_XDVIPDFMX = -Dmain='__attribute__((visibility(\"default\"))) busymain_xdvipdfmx' -Dcheck_for_jpeg=dvipdfmx_check_for_jpeg -Dcheck_for_bmp=dvipdfmx_check_for_bmp -Dcheck_for_png=dvipdfmx_check_for_png -Dseek_absolute=dvidpfmx_seek_absolute -Dseek_relative=dvidpfmx_seek_relative -Dseek_end=dvidpfmx_seek_end -Dtell_position=dvidpfmx_tell_position -Dfile_size=dvidpfmx_file_size -Dmfgets=dvipdfmx_mfgets -Dwork_buffer=dvipdfmx_work_buffer -Dget_unsigned_byte=dvipdfmx_get_unsigned_byte -Dget_unsigned_pair=dvipdfmx_get_unsigned_pair 
CFLAGS_BIBTEX = -Dmain='__attribute__((visibility(\"default\"))) busymain_bibtex8' -Dinitialize=bibtex_initialize -Deoln=bibtex_eoln -Dlast=bibtex_last -Dhistory=bibtex_history -Dbad=bibtex_bad -Dxchr=bibtex_xchr -Dbuffer=bibtex_buffer -Dclose_file=bibtex_close_file -Dusage=bibtex_usage 
CFLAGS_XETEX = -Dmain='__attribute__((visibility(\"default\"))) busymain_xetex'
CFLAGS_KPSEWHICH = -Dmain='__attribute__((visibility(\"default\"))) busymain_kpsewhich'

##############################################################################################################################

# uuid_generate_random feature request: https://github.com/emscripten-core/emscripten/issues/12093
CFLAGS_FONTCONFIG_wasm = -Duuid_generate_random=uuid_generate $(CFLAGS_OPT_wasm)
CFLAGS_FONTCONFIG_native = $(CFLAGS_OPT_native)
CFLAGS_XDVIPDFMX_wasm = $(CFLAGS_XDVIPDFMX) $(CFLAGS_OPT_wasm)
CFLAGS_BIBTEX_wasm = $(CFLAGS_BIBTEX) $(CFLAGS_OPT_wasm) -s TOTAL_MEMORY=$(TOTAL_MEMORY) $(CFLAGS_OPT_wasm)
CFLAGS_XETEX_wasm = $(CFLAGS_XETEX) $(CFLAGS_OPT_wasm)
CFLAGS_XDVIPDFMX_native = $(CFLAGS_XDVIPDFMX) $(CFLAGS_OPT_native)
CFLAGS_BIBTEX_native = $(CFLAGS_BIBTEX) $(CFLAGS_OPT_native)
CFLAGS_XETEX_native = $(CFLAGS_XETEX) $(CFLAGS_OPT_native)
CFLAGS_KPSEWHICH_native = $(CFLAGS_KPSEWHICH) $(CFLAGS_OPT_native)
CFLAGS_TEXLIVE_wasm = -I$(ROOT)/build/wasm/texlive/libs/icu/include -I$(ROOT)/source/fontconfig $(CFLAGS_OPT_wasm) -s ERROR_ON_UNDEFINED_SYMBOLS=0 
CFLAGS_TEXLIVE_native = -I$(ROOT)/build/native/texlive/libs/icu/include -I$(ROOT)/source/fontconfig $(CFLAGS_OPT_native)
CFLAGS_ICU_wasm = $(CFLAGS_OPT_wasm) -s ERROR_ON_UNDEFINED_SYMBOLS=0 
CFLAGS_FONTCONFIGFREETYPE_wasm = $(addprefix -I$(ROOT)/build/wasm/texlive/libs/, freetype2/ freetype2/freetype2/)
CFLAGS_FONTCONFIGFREETYPE_native = $(addprefix -I$(ROOT)/build/native/texlive/libs/, freetype2/ freetype2/freetype2/)
LIBS_FONTCONFIGFREETYPE_wasm = -L$(ROOT)/build/wasm/texlive/libs/freetype2/ -lfreetype
LIBS_FONTCONFIGFREETYPE_native = -L$(ROOT)/build/native/texlive/libs/freetype2/ -lfreetype
PKGDATAFLAGS_ICU_wasm = --without-assembly -O $(ROOT)/build/wasm/texlive/libs/icu/icu-build/data/icupkg.inc

##############################################################################################################################

# EM_COMPILER_WRAPPER / EM_COMPILER_LAUNCHER feature request: https://github.com/emscripten-core/emscripten/issues/12340
CCSKIP_ICU_wasm = $(PYTHON) $(ROOT)/busytex_emcc_wrapper.py $(addprefix $(ROOT)/build/native/texlive/libs/icu/icu-build/bin/, icupkg pkgdata) --
CCSKIP_FREETYPE_wasm = $(PYTHON) $(ROOT)/busytex_emcc_wrapper.py $(ROOT)/build/native/texlive/libs/freetype2/ft-build/apinames --
CCSKIP_XETEX_wasm = $(PYTHON) $(ROOT)/busytex_emcc_wrapper.py $(addprefix $(ROOT)/build/native/texlive/texk/web2c/, ctangle otangle tangle tangleboot ctangleboot tie xetex) $(addprefix $(ROOT)/build/native/texlive/texk/web2c/web2c/, fixwrites makecpool splitup web2c) --
OPTS_ICU_configure_wasm = CC="$(CCSKIP_ICU_wasm) emcc $(CFLAGS_ICU_wasm)" CXX="$(CCSKIP_ICU_wasm) em++ $(CFLAGS_ICU_wasm)"
OPTS_ICU_make_wasm = -e PKGDATA_OPTS="$(PKGDATAFLAGS_ICU_wasm)" -e CC="$(CCSKIP_ICU_wasm) emcc $(CFLAGS_ICU_wasm)" -e CXX="$(CCSKIP_ICU_wasm) em++ $(CFLAGS_ICU_wasm)"
OPTS_BIBTEX_wasm = -e CFLAGS="$(CFLAGS_BIBTEX_wasm)" -e CXXFLAGS="$(CFLAGS_BIBTEX_wasm)"
OPTS_FREETYPE_wasm = CC="$(CCSKIP_FREETYPE_wasm) emcc"
OPTS_XETEX_wasm = CC="$(CCSKIP_XETEX_wasm) emcc $(CFLAGS_XETEX_wasm)" CXX="$(CCSKIP_XETEX_wasm) em++ $(CFLAGS_XETEX_wasm)"
OPTS_XDVIPDFMX_wasm = CC="emcc $(CFLAGS_XDVIPDFMX_wasm)" CXX="em++ $(CFLAGS_XDVIPDFMX_wasm)"
OPTS_XDVIPDFMX_native = -e CFLAGS="$(CFLAGS_TEXLIVE_native) $(CFLAGS_XDVIPDFMX_native)" -e CPPFLAGS="$(CFLAGS_TEXLIVE_native) $(CFLAGS_XDVIPDFMX_native)"
OPTS_BIBTEX_native = -e CFLAGS="$(CFLAGS_BIBTEX_native)" -e CXXFLAGS="$(CFLAGS_BIBTEX_native)"
OPTS_XETEX_native = CC="$(CC) $(CFLAGS_XETEX_native)" CXX="$(CXX) $(CFLAGS_XETEX_native)"
OPTS_KPSEWHICH_native = CFLAGS="$(CFLAGS_KPSEWHICH_native)"

##############################################################################################################################

.PHONY: all
all:
	$(MAKE) texlive
	$(MAKE) native
	$(MAKE) tds-basic
	$(MAKE) wasm
	$(MAKE) build/wasm/fonts.conf
	$(MAKE) build/wasm/texlive-basic.js
	#$(MAKE) tds-full
	#$(MAKE) ubuntu-wasm

source/texlive.downloaded source/expat.downloaded source/fontconfig.downloaded:
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
	echo '' > $(CACHE_TEXLIVE_$*)
	cd $(basename $@) &&                        \
	CONFIG_SITE=$(CONFIGSITE_BUSYTEX) $(CONFIGURE_$*) $(ROOT)/source/texlive/configure		\
	  --cache-file=$(CACHE_TEXLIVE_$*)  		\
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
		CFLAGS="$(CFLAGS_TEXLIVE_$*)"	     	\
	  CPPFLAGS="$(CFLAGS_TEXLIVE_$*)"           \
	  CXXFLAGS="$(CFLAGS_TEXLIVE_$*)"
	$(MAKE_$*) -C $(basename $@)
	touch $@

build/native/texlive/libs/icu/icu-build/lib/libicuuc.a build/native/texlive/libs/icu/icu-build/lib/libicudata.a build/native/texlive/libs/icu/icu-build/bin/icupkg build/native/texlive/libs/icu/icu-build/bin/pkgdata : build/native/texlive.configured
	$(MAKE_native) -C build/native/texlive/libs/icu 
	$(MAKE_native) -C build/native/texlive/libs/icu/icu-build 

build/native/texlive/libs/freetype2/libfreetype.a: build/native/texlive.configured
	$(MAKE_native) -C $(dir $@) 

build/wasm/texlive/libs/freetype2/libfreetype.a: build/wasm/texlive.configured build/native/texlive/libs/freetype2/libfreetype.a
	$(MAKE_wasm) -C $(dir $@) $(OPTS_FREETYPE_wasm)

#build/native/texlive/libs/icu/icu-build/bin/icupkg build/native/texlive/libs/icu/icu-build/bin/pkgdata

build/wasm/texlive/libs/icu/icu-build/lib/libicuuc.a: build/wasm/texlive.configured
	echo LIBICUUC_CONFIGURE
	cd build/wasm/texlive/libs/icu && \
	CONFIG_SITE=$(CONFIGSITE_BUSYTEX) $(CONFIGURE_wasm) $(ROOT)/source/texlive/libs/icu/configure $(OPTS_ICU_configure_wasm)
	echo LIBICUUC_MAKE
	#mkdir -p build/wasm/texlive/libs/icu/icu-build
	#$(CONFIGURE_wasm) $(ROOT)/source/texlive/libs/icu/icu-src/source/configure --enable-static --disable-shared --disable-extras --disable-samples --disable-tests --disable-dyload --disable-layout --disable-strict --build=x86_64-pc-linux-gnu 'CC=/home/runner/work/_temp/bde926b5-511c-47c4-ab06-39d4fcd228e1/emsdk-master/upstream/emscripten/emcc' 'CXX=/home/runner/work/_temp/bde926b5-511c-47c4-ab06-39d4fcd228e1/emsdk-master/upstream/emscripten/em++
	$(MAKE_wasm) -C build/wasm/texlive/libs/icu $(OPTS_ICU_make_wasm) -e icu_config="$(CONFIGURE_wasm) $(ROOT)/source/texlive/libs/icu/icu-src/source/configure --enable-static --disable-shared --disable-extras --disable-samples --disable-tests --disable-dyload --disable-layout" 
	#echo "$(SKIP)" > build/wasm/texlive/libs/icu/icu-build/test/Makefile
	#$(MAKE_wasm) -C build/wasm/texlive/libs/icu/icu-build #$(OPTS_ICU_make_wasm) 

build/%/texlive/libs/teckit/libTECkit.a build/%/texlive/libs/harfbuzz/libharfbuzz.a build/%/texlive/libs/graphite2/libgraphite2.a build/%/texlive/libs/libpng/libpng.a build/%/texlive/libs/libpaper/libpaper.a build/%/texlive/libs/zlib/libz.a build/%/texlive/libs/pplib/libpplib.a: build/%/texlive.configured
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
	echo '' > $(CACHE_FONTCONFIG_$*)
	mkdir -p build/$*/fontconfig
	cd build/$*/fontconfig && \
	$(CONFIGURE_$*) $(ROOT)/$(basename $<)/configure \
	   --cache-file=$(CACHE_FONTCONFIG_$*)		 \
	   --prefix=$(PREFIX_$*) \
	   --sysconfdir=/etc     \
	   --localstatedir=/var  \
	   --enable-static \
	   --disable-shared \
	   --disable-docs \
	   --with-expat-includes="$(ROOT)/source/expat/lib" \
	   --with-expat-lib="$(ROOT)/build/$*/expat" \
	   CFLAGS="$(CFLAGS_FONTCONFIG_$*) -v" FREETYPE_CFLAGS="$(CFLAGS_FONTCONFIGFREETYPE_$*)" FREETYPE_LIBS="$(LIBS_FONTCONFIGFREETYPE_$*)"
	$(MAKE_$*) -C build/$*/fontconfig

build/%/texlive/texk/web2c/lib/lib.a: build/%/texlive.configured
	$(MAKE_$*) -C $(dir $@) $(notdir $@)

build/%/texlive/texk/kpathsea/.libs/libkpathsea.a: build/%/texlive.configured
	$(MAKE_$*) -C build/$*/texlive/texk/kpathsea

build/%/texlive/texk/kpathsea/kpsewhich.o: build/%/texlive.configured
	$(MAKE_$*) -C $(dir $@) $(notdir $@) $(OPTS_KPSEWHICH_$*)


################################################################################################################

build/native/texlive/texk/bibtex-x/bibtex8.a: build/native/texlive.configured
	$(MAKE_native) -C $(dir $@) $(subst -Dmain, -Dbusymain, $(OPTS_BIBTEX_native))
	rm $(dir $@)/bibtex8-bibtex.o
	$(MAKE_native) -C $(dir $@) bibtex8-bibtex.o $(OPTS_BIBTEX_native)
	$(AR_native) -crs $@ $(dir $@)/bibtex8-*.o

build/native/texlive/texk/dvipdfm-x/xdvipdfmx.a: build/native/texlive.configured
	$(MAKE_native) -C $(dir $@) $(subst -Dmain, -Dbusymain, $(OPTS_XDVIPDFMX_native))
	rm $(dir $@)/dvipdfmx.o
	$(MAKE_native) -C $(dir $@) dvipdfmx.o $(OPTS_XDVIPDFMX_native)
	$(AR_native) -crs $@ $(dir $@)/*.o

build/native/texlive/texk/web2c/libxetex.a: build/native/texlive.configured
	$(MAKE_native) -C $(dir $@) synctexdir/xetex-synctex.o xetex $(subst -Dmain, -Dbusymain, $(OPTS_XETEX_native))
	rm $(dir $@)/xetexdir/xetex-xetexextra.o
	$(MAKE_native) -C $(dir $@) xetexdir/xetex-xetexextra.o $(OPTS_XETEX_native)
	$(MAKE_native) -C $(dir $@) $(notdir $@) $(OPTS_XETEX_native)

.PHONY: build/native/busytex
build/native/busytex: 
	mkdir -p $(dir $@)
	$(CC) -c busytex.c -o busytex.o
	$(CXX)  $(CFLAGS_OPT_native) -o $@ -lm -pthread busytex.o $(addprefix build/native/texlive/texk/kpathsea/, $(OBJ_KPATHSEA)) $(addprefix build/native/texlive/texk/web2c/, $(OBJ_XETEX)) $(addprefix build/native/, $(OBJ_DVIPDF) $(OBJ_BIBTEX) $(OBJ_DEPS)) $(addprefix -Ibuild/native/, $(CPATH_BUSYTEX)) 

################################################################################################################

build/wasm/texlive/texk/bibtex-x/bibtex8.a: build/wasm/texlive.configured
	$(MAKE_wasm) -C $(dir $@) $(OPTS_BIBTEX_wasm)
	$(AR_wasm) -crs $@ $(dir $@)/bibtex8-*.o

build/wasm/texlive/texk/dvipdfm-x/xdvipdfmx.a: build/wasm/texlive.configured
	$(MAKE_wasm) -C $(dir $@) $(OPTS_XDVIPDFMX_wasm)
	$(AR_wasm) -crs $@ $(dir $@)/*.o

build/wasm/texlive/texk/web2c/libxetex.a: build/wasm/texlive.configured
	# copying generated C files from native version, since string offsets are off
	mkdir -p $(dir $@)
	cp build/native/texlive/texk/web2c/*.c $(dir $@)
	$(MAKE_wasm) -C $(dir $@) synctexdir/xetex-synctex.o xetex $(OPTS_XETEX_wasm)

build/wasm/busytex.js: 
	mkdir -p $(dir $@)
	emcc $(CFLAGS_OPT) -s TOTAL_MEMORY=$(TOTAL_MEMORY) -s EXIT_RUNTIME=0 -s INVOKE_RUN=0  -s ASSERTIONS=1 -s ERROR_ON_UNDEFINED_SYMBOLS=0 -s FORCE_FILESYSTEM=1 -s LZ4=1 -s MODULARIZE=1 -s EXPORT_NAME=$(notdir $(basename $@)) -s EXPORTED_FUNCTIONS='["_main"]' -s EXPORTED_RUNTIME_METHODS='["callMain","FS", "ENV", "allocateUTF8OnStack", "LZ4", "PATH"]' -o $@ -lm $(addprefix build/wasm/texlive/texk/web2c/, $(OBJ_XETEX)) $(addprefix build/wasm/, $(OBJ_DVIPDF) $(OBJ_BIBTEX) $(OBJ_DEPS)) $(addprefix -Ibuild/wasm/, $(CPATH_BUSYTEX)) busytex.c

################################################################################################################

build/install-tl/install-tl:
	mkdir -p $(dir $@)
	wget --no-clobber $(URL_TEXLIVE_INSTALLER) -P source || true
	tar -xf source/$(notdir $(URL_TEXLIVE_INSTALLER)) --strip-components=1 --directory="$(dir $@)"

build/texlive-%/texmf-dist: build/install-tl/install-tl 
	# https://www.tug.org/texlive/doc/install-tl.html
	#TODO: find texlive-$*/ -executable -type f -exec rm {} +
	mkdir -p $(dir $@)
	echo selected_scheme scheme-$* > build/texlive-$*.profile
	echo TEXDIR $(ROOT)/$(dir $@) >> build/texlive-$*.profile
	echo TEXMFLOCAL $(ROOT)/$(basename $@)/texmf-local >> build/texlive-$*.profile
	echo TEXMFSYSVAR $(ROOT)/$(basename $@)/texmf-var >> build/texlive-$*.profile
	echo TEXMFSYSCONFIG $(ROOT)/$(basename $@)/texmf-config >> build/texlive-$*.profile
	#echo TEXMFVAR $(ROOT)/$(basename $@)/home/texmf-var >> build/texlive-$*.profile
	TEXLIVE_INSTALL_NO_RESUME=1 $< -profile build/texlive-$*.profile
	rm -rf $(addprefix $(dir $@)/, bin readme* tlpkg install* *.html texmf-dist/doc texmf-var/doc texmf-var/web2c readme-html.dir readme-txt.dir) || true

build/format-%/latex.fmt: build/native/busytex build/texlive-%/texmf-dist 
	mkdir -p $(dir $@)
	rm $(dir $@)/* || true
	TEXINPUTS=build/texlive-basic/texmf-dist/source/latex/base TEXMFCNF=build/texlive-$*/texmf-dist/web2c TEXMFDIST=build/texlive-$*/texmf-dist $(XETEX) --interaction=nonstopmode --halt-on-error --output-directory=$(dir $@) -ini -etex unpack.ins
	TEXINPUTS=build/texlive-basic/texmf-dist/source/latex/base:build/texlive-basic/texmf-dist/tex/generic/unicode-data:build/texlive-basic/texmf-dist/tex/latex/base:build/texlive-basic/texmf-dist/tex/generic/hyphen:build/texlive-basic/texmf-dist/tex/latex/l3kernel:build/texlive-basic/texmf-dist/tex/latex/l3packages/xparse TEXMFCNF=build/texlive-$*/texmf-dist/web2c TEXMFDIST=build/texlive-$*/texmf-dist $(XETEX) --interaction=nonstopmode --halt-on-error --output-directory=$(dir $@) -ini -etex latex.ltx

build/wasm/texlive-%.js: build/format-%/latex.fmt build/texlive-%/texmf-dist build/wasm/fonts.conf 
	mkdir -p $(dir $@)
	echo > build/empty
	$(PYTHON) $(EMROOT)/tools/file_packager.py $(basename $@).data --js-output=$@ --export-name=BusytexPipeline \
		--lz4 --use-preload-cache \
		--preload build/empty@/bin/busytex \
		--preload build/wasm/fonts.conf@/etc/fonts/fonts.conf \
		--preload build/texlive-$*@/texlive \
		--preload build/format-$*/latex.fmt@/latex.fmt 

build/wasm/ubuntu-%.js: $(TEXMF_FULL)
	mkdir -p $(dir $@)
	$(PYTHON) $(EMROOT)/tools/file_packager.py $(basename $@).data --js-output=$@ --export-name=BusytexPipeline \
		--lz4 --use-preload-cache \
		$(shell $(PYTHON) ubuntu_package_preload.py --texmf $(TEXMF_FULL) --url $(URL_UBUNTU_RELEASE) --package $*)

build/wasm/fonts.conf:
	mkdir -p $(dir $@)
	echo '<?xml version="1.0"?>' > $@
	echo '<!DOCTYPE fontconfig SYSTEM "fonts.dtd">' >> $@
	echo '<fontconfig>' >> $@
	echo '<dir>/texlive/texmf-dist/fonts/opentype</dir>' >> $@
	echo '<dir>/texlive/texmf-dist/fonts/type1</dir>' >> $@
	echo '</fontconfig>' >> $@

build/native/fonts.conf:
	mkdir -p $(dir $@)
	echo '<?xml version="1.0"?>' > $@
	echo '<!DOCTYPE fontconfig SYSTEM "fonts.dtd">' >> $@
	echo '<fontconfig>' >> $@
	#<dir prefix="relative">../texlive-basic/texmf-dist/fonts/opentype</dir>
	#<dir prefix="relative">../texlive-basic/texmf-dist/fonts/type1</dir>
	#<cachedir prefix="relative">./cache</cachedir>
	echo '</fontconfig>' >> $@

################################################################################################################


.PHONY: texlive
texlive:
	$(MAKE) source/texlive.downloaded source/texlive.patched

.PHONY: native
native: 
	$(MAKE) build/native/texlive.configured
	$(MAKE) build/native/texlive/libs/libpng/libpng.a 
	$(MAKE) build/native/texlive/libs/libpaper/libpaper.a 
	$(MAKE) build/native/texlive/libs/zlib/libz.a 
	$(MAKE) build/native/texlive/libs/teckit/libTECkit.a 
	$(MAKE) build/native/texlive/libs/harfbuzz/libharfbuzz.a 
	$(MAKE) build/native/texlive/libs/graphite2/libgraphite2.a 
	$(MAKE) build/native/texlive/libs/pplib/libpplib.a 
	$(MAKE) build/native/texlive/libs/freetype2/libfreetype.a 
	$(MAKE) build/native/texlive/libs/icu/icu-build/lib/libicuuc.a 
	$(MAKE) build/native/texlive/libs/icu/icu-build/lib/libicudata.a
	$(MAKE) build/native/texlive/libs/icu/icu-build/bin/icupkg 
	$(MAKE) build/native/texlive/libs/icu/icu-build/bin/pkgdata 
	$(MAKE) build/native/expat/libexpat.a
	$(MAKE) build/native/fontconfig/src/.libs/libfontconfig.a
	# 
	$(MAKE) build/native/texlive/texk/kpathsea/.libs/libkpathsea.a
	$(MAKE) build/native/texlive/texk/web2c/lib/lib.a
	rm build/native/texlive/texk/kpathsea/kpsewhich.o || true
	$(MAKE) build/native/texlive/texk/kpathsea/kpsewhich.o 
	$(MAKE) build/native/texlive/texk/bibtex-x/bibtex8.a
	$(MAKE) build/native/texlive/texk/dvipdfm-x/xdvipdfmx.a
	$(MAKE) build/native/texlive/texk/web2c/libxetex.a
	$(MAKE) build/native/busytex

#.PHONY: tds-basic tds-small tds-full
tds-%:
	$(MAKE) build/install-tl/install-tl
	$(MAKE) build/texlive-$*/texmf-dist
	$(MAKE) build/format-$*/latex.fmt

# https://packages.ubuntu.com/groovy/tex/ https://packages.ubuntu.com/source/groovy/texlive-extra
.PHONY: ubuntu-wasm
ubuntu-wasm: build/wasm/ubuntu-texlive-latex-base.js build/wasm/ubuntu-texlive-latex-extra.js build/wasm/ubuntu-texlive-latex-recommended.js

.PHONY: wasm
wasm:
	$(MAKE) build/wasm/texlive.configured
	$(MAKE) build/wasm/texlive/libs/icu/icu-build/lib/libicuuc.a 
	#$(MAKE) build/wasm/texlive/libs/libpng/libpng.a 
	#$(MAKE) build/wasm/texlive/libs/libpaper/libpaper.a 
	#$(MAKE) build/wasm/texlive/libs/zlib/libz.a 
	#$(MAKE) build/wasm/texlive/libs/teckit/libTECkit.a 
	#$(MAKE) build/wasm/texlive/libs/harfbuzz/libharfbuzz.a 
	#$(MAKE) build/wasm/texlive/libs/graphite2/libgraphite2.a 
	#$(MAKE) build/wasm/texlive/libs/pplib/libpplib.a 
	#$(MAKE) build/wasm/texlive/libs/freetype2/libfreetype.a 
	#$(MAKE) build/wasm/texlive/libs/icu/icu-build/lib/libicuuc.a 
	#$(MAKE) build/wasm/texlive/libs/icu/icu-build/lib/libicudata.a
	#$(MAKE) build/wasm/expat/libexpat.a
	#$(MAKE) build/wasm/fontconfig/src/.libs/libfontconfig.a
	##
	#$(MAKE) build/wasm/texlive/texk/kpathsea/.libs/libkpathsea.a
	#$(MAKE) build/wasm/texlive/texk/web2c/lib/lib.a
	#rm build/wasm/texlive/texk/kpathsea/kpsewhich.o || true
	#$(MAKE) build/wasm/texlive/texk/kpathsea/kpsewhich.o 
	#$(MAKE) build/wasm/texlive/texk/bibtex-x/bibtex8.a
	#$(MAKE) build/wasm/texlive/texk/dvipdfm-x/xdvipdfmx.a
	#$(MAKE) build/wasm/texlive/texk/web2c/libxetex.a
	#$(MAKE) build/wasm/busytex.js

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

.PHONY: clean_build
clean_build:
	rm -rf build

.PHONY: clean_example
clean_example:
	rm -rf example/*.aux example/*.bbl example/*.blg example/*.log example/*.xdv

.PHONY: clean
clean:
	rm -rf build source

.PHONY: dist-wasm
dist-wasm:
	mkdir -p dist
	cp build/wasm/busytex.js build/wasm/busytex.wasm dist
	cp build/wasm/texlive-basic.js build/wasm/texlive-basic.data dist
	cp build/wasm/ubuntu-*.js build/wasm/ubuntu-*.data dist

.PHONY: dist-native
dist-native: build/native/busytex build/native/fonts.conf
	mkdir -p dist
	cp build/native/busytex build/native/fonts.conf build/format-basic/latex.fmt dist
	cp -r build/texlive-basic dist/texlive
