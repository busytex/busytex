# good https://github.com/busytex/busytex/blob/e95e9cce4b5be1f932a06cb078ada701687d1c69/Makefile
# http://www.linuxfromscratch.org/blfs/view/svn/pst/texlive.html
# https://www.tug.org/texlive//devsrc/Master/texmf-dist/tex/latex/

#URL_texlive_full_iso = http://mirrors.ctan.org/systems/texlive/Images/texlive2023-20230313.iso
URL_texlive_full_iso_cache = https://github.com/busytex/busytex/releases/download/texlive2023-20230313.iso/texlive2023-20230313.iso.00 https://github.com/busytex/busytex/releases/download/texlive2023-20230313.iso/texlive2023-20230313.iso.01 https://github.com/busytex/busytex/releases/download/texlive2023-20230313.iso/texlive2023-20230313.iso.02 https://github.com/busytex/busytex/releases/download/texlive2023-20230313.iso/texlive2023-20230313.iso.03 https://github.com/busytex/busytex/releases/download/texlive2023-20230313.iso/texlive2023-20230313.iso.04
URL_texlive_full_iso = https://tug.ctan.org/systems/texlive/Images/texlive2023-20230313.iso
URL_texlive          = https://github.com/TeX-Live/texlive-source/archive/refs/heads/tags/texlive-2023.0.tar.gz
URL_expat            = https://github.com/libexpat/libexpat/releases/download/R_2_5_0/expat-2.5.0.tar.gz
URL_fontconfig       = https://www.freedesktop.org/software/fontconfig/release/fontconfig-2.13.96.tar.gz
URL_ubuntu_release   = https://packages.ubuntu.com/lunar/

BUSYTEX_BIN          = busytex fonts.conf
BUSYTEX_TEXBIN       = ctangle otangle tangle tangleboot ctangleboot tie
BUSYTEX_WEB2CBIN     = fixwrites makecpool splitup web2c


TOTAL_MEMORY         = 536870912
CFLAGS_OPT_native    = -O3
# Explicitly enable exceptions and RTTI in case they are disabled by default (such as in Cosmopolitan Libc).
CXXFLAGS_native      = -fexceptions -frtti
CFLAGS_OPT_wasm      = -Oz

ROOT                := $(CURDIR)
EMROOT              := $(dir $(shell which emcc))

BUSYTEX_native       = $(abspath build/native/busytex)
TEXMFFULL            = $(abspath build/texlive-full)
PREFIX_wasm          = $(abspath build/wasm/prefix)
PREFIX_native        = $(abspath build/native/prefix)

BINARCH_native =bin/_custom

PYTHON        = python3
PERL          = perl
MAKE_wasm     = emmake $(MAKE)
CMAKE_wasm    = emcmake cmake
CONFIGURE_wasm= $(EMROOT)/emconfigure
AR_wasm       = emar
CC_wasm       = emcc
CXX_wasm      = em++
NM_wasm       = $(EMROOT)/../bin/llvm-nm
OBJCOPY_wasm  = echo # TODO: use `llvm-objcopy` here
LDR_wasm      = echo # TODO: use `wasm-ld -r` here
CC_native     = $(CC)
CXX_native    = $(CXX)
MAKE_native   = $(MAKE)
CMAKE_native  = cmake
OBJCOPY      ?= objcopy
OBJCOPY_native= $(OBJCOPY)
AR_native     = $(AR)
LDR          ?= ld -r
LDR_native    = $(LDR)
NM_native     = nm
LDD_native    = ldd

CACHE_TEXLIVE_native    = $(abspath build/native-texlive.cache)
CACHE_TEXLIVE_wasm      = $(abspath build/wasm-texlive.cache)
CACHE_FONTCONFIG_native = $(abspath build/native-fontconfig.cache)
CACHE_FONTCONFIG_wasm   = $(abspath build/wasm-fontconfig.cache)
CONFIGSITE_BUSYTEX      = $(abspath busytex.site)

CPATH_BUSYTEX = texlive/libs/icu/include fontconfig

##############################################################################################################################

OBJ_LUAHBTEX  = busytex_libluahbtex.o
OBJ_PDFTEX    = busytex_libpdftex.o
OBJ_XETEX     = busytex_libxetex.o
OBJ_DVIPDF    = texlive/texk/dvipdfm-x/busytex_xdvipdfmx.o
OBJ_MAKEINDEX = texlive/texk/makeindexk/busytex_makeindex.o
OBJ_BIBTEX    = texlive/texk/bibtex-x/busytex_bibtex8.o
OBJ_KPATHSEA  = busytex_kpsewhich.o busytex_kpsestat.o busytex_kpseaccess.o busytex_kpsereadlink.o .libs/libkpathsea.a
 
OBJ_DEPS      = $(addprefix texlive/libs/, harfbuzz/libharfbuzz.a graphite2/libgraphite2.a teckit/libTECkit.a libpng/libpng.a) fontconfig/src/.libs/libfontconfig.a $(addprefix texlive/libs/, freetype2/libfreetype.a pplib/libpplib.a zlib/libz.a zziplib/libzzip.a libpaper/libpaper.a icu/icu-build/lib/libicuuc.a icu/icu-build/lib/libicudata.a lua53/.libs/libtexlua53.a xpdf/libxpdf.a) texlive/texk/kpathsea/.libs/libkpathsea.a expat/libexpat.a texlive/texk/web2c/libmd5.a

OBJ_DEPS_XETEX= fontconfig/src/.libs/libfontconfig.a $(addprefix texlive/libs/, icu/icu-build/lib/libicuuc.a icu/icu-build/lib/libicudata.a) 


##############################################################################################################################

# LuaTeX unconditionally builds the `luasocket` module: https://github.com/TeX-Live/texlive-source/blob/tags/texlive-2023.0/texk/web2c/Makefile.am#L292
# `luasocket` depends on various macros that require additional feature test macros. For example `gethostbyaddr()` requires `_GNU_SOURCE` or similar:
# https://github.com/TeX-Live/texlive-source/blob/tags/texlive-2023.0/texk/web2c/luatexdir/luasocket/src/usocket.c#L381
# The `configure.ac` for `web2c` (which also configures LuaTeX) should therefore contain something like `AC_USE_SYSTEM_EXTENSIONS`:
# https://www.gnu.org/software/autoconf/manual/autoconf-2.67/html_node/Posix-Variants.html
# However, it doesn't. The build still works with musl because some of its headers indirectly include `features.h` that defaults to `_BSD_SOURCE`, which is enough:
# https://git.musl-libc.org/cgit/musl/tree/include/features.h?h=v1.2.4#n15
# Cosmopolitan doesn't include `features.h` indirectly, so we have to define a sufficiently powerful macro (`_GNU_SOURCE`) right here.
# Also, the default `socket_waitfd()` implementation in `luasocket` includes a non-standard `sys/poll.h` header, which doesn't contain `struct pollfd` in Cosmopolitan:
# https://github.com/TeX-Live/texlive-source/blob/tags/texlive-2023.0/texk/web2c/luatexdir/luasocket/src/usocket.c#L19
# By defining `SOCKET_SELECT`, we fall back to a simple `socket_waitfd()` implementation that uses `select()` instead, which is perfectly fine for LuaTeX.
LUATEX_SOCKET_DEFINES = -D_GNU_SOURCE -DSOCKET_SELECT

# The TeX sources contains a function called `privileged`, which is then translated into a C function:
# https://github.com/TeX-Live/texlive-source/blob/tags/texlive-2023.0/texk/web2c/tex.web#L20459
# The prelude from Cosmopolitan Libc #defines `privileged` to mean something else, unless the macro is already defined:
# https://github.com/jart/cosmopolitan/blob/d5225a693bbb6c916d84c0f3e88a9156707d461f/libc/integral/c.inc#L194
# Use a dummy define to prevent Cosmopolitan from clobbering `privileged`.
UNPRIVILEGED        := -Dprivileged=privileged
CFLAGS_XETEX        := $(UNPRIVILEGED)
CFLAGS_BIBTEX       := $(UNPRIVILEGED)
CFLAGS_XDVIPDFMX    := $(UNPRIVILEGED)
CFLAGS_PDFTEX       := $(UNPRIVILEGED)
CFLAGS_LUAHBTEX     := $(UNPRIVILEGED) $(LUATEX_SOCKET_DEFINES)
CFLAGS_LUATEX       := $(UNPRIVILEGED) $(LUATEX_SOCKET_DEFINES)

##############################################################################################################################

# uuid_generate_random feature request: https://github.com/emscripten-core/emscripten/issues/12093
CFLAGS_FONTCONFIG_wasm= -Duuid_generate_random=uuid_generate -pthread
# -pthread
CFLAGS_BIBTEX_wasm      = $(CFLAGS_BIBTEX) -sTOTAL_MEMORY=$(TOTAL_MEMORY)
CFLAGS_ICU_wasm         = $(CFLAGS_OPT_wasm) -sERROR_ON_UNDEFINED_SYMBOLS=0
CFLAGS_TEXLIVE_wasm     = -I$(abspath build/wasm/texlive/libs/icu/include)   -I$(abspath source/fontconfig) $(CFLAGS_OPT_wasm) -sERROR_ON_UNDEFINED_SYMBOLS=0 -Wno-error=unused-but-set-variable
CXXFLAGS_TEXLIVE_wasm   = $(CFLAGS_TEXLIVE_wasm)
CFLAGS_TEXLIVE_native   = -I$(abspath build/native/texlive/libs/icu/include) -I$(abspath source/fontconfig) $(CFLAGS_OPT_native)
CXXFLAGS_TEXLIVE_native = $(CFLAGS_TEXLIVE_native) $(CXXFLAGS_native)
# https://tug.org/pipermail/tlbuild/2021q1/004774.html
# https://github.com/emscripten-core/emscripten/issues/14973
# -static-libstdc++ -static-libgcc
# -nodefaultlibs -Wl,-Bstatic -lstdc++ -Wl,-Bdynamic -lgcc
# -fno-common 

# https://www.openwall.com/lists/musl/2017/02/16/3
LDFLAGS_TEXLIVE_native = --static -static -static-libstdc++ -static-libgcc -ldl -lm -pthread -lpthread -lc

# The WASM build can't assemble `.s` files when building pkgdata for obvious reasons.
PKGDATAFLAGS_ICU_wasm   = --without-assembly -O $(ROOT)/build/wasm/texlive/libs/icu/icu-build/data/icupkg.inc
# Cosmopolitan builds a fat multi-arch executable, so it, too, refuses to process raw `.s` files.
PKGDATAFLAGS_ICU_native = --without-assembly -O $(ROOT)/build/native/texlive/libs/icu/icu-build/data/icupkg.inc

##############################################################################################################################

# EM_COMPILER_WRAPPER / EM_COMPILER_LAUNCHER feature request: https://github.com/emscripten-core/emscripten/issues/12340
CCSKIP_ICU_wasm          = $(PYTHON) $(abspath emcc_wrapper.py) $(addprefix $(ROOT)/build/native/texlive/libs/icu/icu-build/bin/, icupkg pkgdata) --
CCSKIP_FREETYPE_wasm     = $(PYTHON) $(abspath emcc_wrapper.py) $(ROOT)/build/native/texlive/libs/freetype2/ft-build/apinames --
CCSKIP_TEX_wasm          = $(PYTHON) $(abspath emcc_wrapper.py) $(addprefix $(ROOT)/build/native/texlive/texk/web2c/, $(BUSYTEX_TEXBIN)) $(addprefix $(ROOT)/build/native/texlive/texk/web2c/web2c/, $(BUSYTEX_WEB2CBIN)) --
OPTS_ICU_configure_wasm  = CC="$(CCSKIP_ICU_wasm) emcc $(CFLAGS_ICU_wasm)" CXX="$(CCSKIP_ICU_wasm) em++ $(CFLAGS_ICU_wasm)"
OPTS_ICU_make_wasm       = -e PKGDATA_OPTS="$(PKGDATAFLAGS_ICU_wasm)"   -e CC="$(CCSKIP_ICU_wasm) emcc $(CFLAGS_ICU_wasm)" -e CXX="$(CCSKIP_ICU_wasm) em++ $(CFLAGS_ICU_wasm)"
OPTS_ICU_make_native     = -e PKGDATA_OPTS="$(PKGDATAFLAGS_ICU_native)" -e CC="$(CC_native) $(CFLAGS_OPT_native)"          -e CXX="$(CXX_native) $(CFLAGS_OPT_native) $(CXXFLAGS_native)"
OPTS_ICU_configure_make_wasm   = $(OPTS_ICU_make_wasm) -e abs_srcdir="'$(CONFIGURE_wasm) $(ROOT)/source/texlive/libs/icu'"
OPTS_ICU_configure_make_native = $(OPTS_ICU_make_native)
OPTS_BIBTEX_wasm         = -e CFLAGS="$(CFLAGS_OPT_wasm) $(CFLAGS_BIBTEX_wasm)" -e CXXFLAGS="$(CFLAGS_OPT_wasm) $(CFLAGS_BIBTEX_wasm)"
OPTS_libfreetype_wasm    = CC="$(CCSKIP_FREETYPE_wasm) emcc"
OPTS_XETEX_wasm          = CC="$(CCSKIP_TEX_wasm)      emcc $(CFLAGS_XETEX)  $(CFLAGS_OPT_wasm)" CXX="$(CCSKIP_TEX_wasm) em++ $(CFLAGS_XETEX)  $(CFLAGS_OPT_wasm)"
OPTS_PDFTEX_wasm         = CC="$(CCSKIP_TEX_wasm)      emcc $(CFLAGS_PDFTEX) $(CFLAGS_OPT_wasm)" CXX="$(CCSKIP_TEX_wasm) em++ $(CFLAGS_PDFTEX) $(CFLAGS_OPT_wasm)"
OPTS_XDVIPDFMX_wasm      = CC="emcc $(CFLAGS_XDVIPDFMX)    $(CFLAGS_OPT_wasm)" CXX="em++          $(CFLAGS_XDVIPDFMX)    $(CFLAGS_OPT_wasm)"
OPTS_XDVIPDFMX_native    = -e CFLAGS="$(CFLAGS_TEXLIVE_native) $(CFLAGS_XDVIPDFMX)    $(CFLAGS_OPT_native)" -e CXXFLAGS="$(CXXFLAGS_TEXLIVE_native) $(CFLAGS_XDVIPDFMX) $(CFLAGS_OPT_native) $(CXXFLAGS_native)"
OPTS_BIBTEX_native       = -e CFLAGS="$(CFLAGS_BIBTEX)         $(CFLAGS_OPT_native)" -e CXXFLAGS="$(CFLAGS_BIBTEX)       $(CFLAGS_OPT_native) $(CXXFLAGS_native)"
OPTS_XETEX_native        = CC="$(CC_native) $(CFLAGS_XETEX)    $(CFLAGS_OPT_native)" CXX="$(CXX_native) $(CFLAGS_XETEX)  $(CFLAGS_OPT_native) $(CXXFLAGS_native)"
OPTS_PDFTEX_native       = CC="$(CC_native) $(CFLAGS_PDFTEX)   $(CFLAGS_OPT_native)" CXX="$(CXX_native) $(CFLAGS_PDFTEX) $(CFLAGS_OPT_native) $(CXXFLAGS_native)"
OPTS_LUAHBTEX_native     = CC="$(CC_native) $(CFLAGS_LUAHBTEX) $(CFLAGS_OPT_native)" CXX="$(CXX_native) $(CFLAGS_LUAHBTEX) $(CFLAGS_OPT_native) $(CXXFLAGS_native)"
OPTS_LUAHBTEX_wasm       = CC="$(CCSKIP_TEX_wasm) emcc $(CFLAGS_LUAHBTEX)   $(CFLAGS_OPT_wasm)" CXX="$(CCSKIP_TEX_wasm) em++ $(CFLAGS_LUAHBTEX)       $(CFLAGS_OPT_wasm)"
OPTS_KPSEWHICH_native    = CFLAGS="$(CFLAGS_OPT_native)"
OPTS_KPSEWHICH_wasm      = CFLAGS="$(CFLAGS_OPT_wasm)"
OPTS_KPSESTAT_native     = CFLAGS="$(CFLAGS_OPT_native)"
OPTS_KPSESTAT_wasm       = CFLAGS="$(CFLAGS_OPT_wasm)"
OPTS_KPSEACCESS_native   = CFLAGS="$(CFLAGS_OPT_native)"
OPTS_KPSEACCESS_wasm     = CFLAGS="$(CFLAGS_OPT_wasm)"
OPTS_KPSEREADLINK_native = CFLAGS="$(CFLAGS_OPT_native)"
OPTS_KPSEREADLINK_wasm   = CFLAGS="$(CFLAGS_OPT_wasm)"
OPTS_MAKEINDEX_native    = CFLAGS="$(CFLAGS_OPT_native)"
OPTS_MAKEINDEX_wasm      = CFLAGS="$(CFLAGS_OPT_wasm)"

# Some of the libraries in libs/ don't use `libtool`, which leads to `AR` being hardcoded to `ar`.
# An example of a "bad" library: https://github.com/TeX-Live/texlive-source/blob/tags/texlive-2023.0/libs/teckit/Makefile.in#L113
# An example of a "good" library: https://github.com/TeX-Live/texlive-source/blob/tags/texlive-2023.0/libs/pplib/Makefile.in#L537
# Force everyone to respect proper `AR`.
OPTS_LIBS_native         = AR=$(AR_native)

OPTS_BUSYTEX_COMPILE_native = -DBUSYTEX_MAKEINDEX -DBUSYTEX_KPSE -DBUSYTEX_BIBTEX8 -DBUSYTEX_XDVIPDFMX -DBUSYTEX_XETEX -DBUSYTEX_PDFTEX -DBUSYTEX_LUATEX
OPTS_BUSYTEX_COMPILE_wasm   = -DBUSYTEX_MAKEINDEX -DBUSYTEX_KPSE -DBUSYTEX_BIBTEX8 -DBUSYTEX_XDVIPDFMX -DBUSYTEX_XETEX -DBUSYTEX_PDFTEX -DBUSYTEX_LUATEX

#####COMMENT NEXT LINE TO TEST SHARED LIBRARY LOG FILE ACCESSES ON NATIVE
OPTS_BUSYTEX_LINK = --static -static    -static-libstdc++ -static-libgcc
OPTS_BUSYTEX_LINK_native =  $(OPTS_BUSYTEX_LINK) -ldl -lm -pthread -lpthread
OPTS_BUSYTEX_LINK_wasm   =  $(OPTS_BUSYTEX_LINK) -Wl,--unresolved-symbols=ignore-all -Wl,-error-limit=0 -sTOTAL_MEMORY=$(TOTAL_MEMORY) -sEXIT_RUNTIME=0 -sINVOKE_RUN=0 -sASSERTIONS=1 -sERROR_ON_UNDEFINED_SYMBOLS=0 -sFORCE_FILESYSTEM=1 -sLZ4=1 -sMODULARIZE=1 -sEXPORT_NAME=busytex -sEXPORTED_FUNCTIONS='["_main", "_flush_streams"]' -sEXPORTED_RUNTIME_METHODS='["callMain", "FS", "ENV", "LZ4", "PATH"]'

##############################################################################################################################

# Prelinks the given `.o`/`.a` files into a new `.o` file.
# Arguments:
#   * $(1): the files to prelink
#   * $(2): the new name of the main function
define PRELINK
# For Cosmo builds, this section is auto-generated by `gcc` when
# `-fpatchable-function-entry=...` is used for `--ftrace` support.
# The section is actually unused, and will eventually be removed by
# the Cosmo linker script when linking the final binary.
# However, we need to remove them right here, otherwise a relocation
# corresponding to one of the entries might reference a COMDAT group
# from a C++ file (for example, in XeTeX) that is discarded on `ld -r`.
# This leads to a linker warning in `ld.lld` and an error in `ld.bfd`.
$(foreach name,$(1),$(OBJCOPY_$*) --remove-section=__patchable_function_entries $(name))

$(LDR_$*) $@ $(1)
$(call BUSYTEXIZE,$@,$(2))
endef

# This macro hides everything except the main function in `.o`/`.a` files.
# Arguments:
#   * $(1): the original `.o` or `.a` basename
#   * $(2): the new name of the main function
BUSYTEXIZE = $(OBJCOPY_$*) --redefine-sym main=$(2) --keep-global-symbol=main $(1) $@

source/texlive.downloaded source/expat.downloaded source/fontconfig.downloaded:
	mkdir -p $(basename $@)
	-wget --no-verbose --no-clobber $(URL_$(notdir $(basename $@))) -O $(basename $@).tar.gz 
	tar -xf "$(basename $@).tar.gz" --strip-components=1 --directory=$(basename $@)
	touch $@

source/texlive.patched: source/texlive.downloaded
	# Cosmopolitan Libc doesn't support arguments with spaces; remove an extra trailing space here:
	# https://github.com/TeX-Live/texlive-source/blob/tags/texlive-2023.0/libs/icu/icu-src/source/common/Makefile.in#L72
	sed -i 's@" "@""@' $(abspath source/texlive/libs/icu/icu-src/source/common/Makefile.in)
	# See the contents of `cosmo_getpass.h` for more details.
	cp cosmo_getpass.h                    $(abspath source/texlive/texk/dvipdfm-x/cosmo_getpass.h)
	sed -i '1i#include "cosmo_getpass.h"' $(abspath source/texlive/texk/dvipdfm-x/dvipdfmx.c)
	touch $@

build/%/texlive.configured: source/texlive.patched
	mkdir -p $(basename $@)
	echo '' > $(CACHE_TEXLIVE_$*)
	#CONFIG_SITE=$(CONFIGSITE_BUSYTEX) $(CONFIGURE_$*) $(abspath source/texlive/configure)		
	cd $(basename $@) &&                                \
	$(CONFIGURE_$*) $(abspath source/texlive/configure) \
	  --cache-file=$(CACHE_TEXLIVE_$*)                  \
	  --prefix="$(PREFIX_$*)"                           \
	  --enable-dump-share                               \
	  --enable-static                                   \
	  --enable-freetype2                                \
	  --disable-shared                                  \
	  --disable-multiplatform                           \
	  --disable-native-texlive-build                    \
	  --disable-all-pkgs                                \
	  --without-x                                       \
	  --without-system-cairo                            \
	  --without-system-gmp                              \
	  --without-system-graphite2                        \
	  --without-system-harfbuzz                         \
	  --without-system-libgs                            \
	  --without-system-libpaper                         \
	  --without-system-mpfr                             \
	  --without-system-pixman                           \
	  --without-system-poppler                          \
	  --without-system-xpdf                             \
	  --without-system-icu                              \
	  --without-system-fontconfig                       \
	  --without-system-freetype2                        \
	  --without-system-libpng                           \
	  --without-system-zlib                             \
	  --without-system-zziplib                          \
	  --with-banner-add="_busytex$*"                    \
	  --enable-cxx-runtime-hack=yes                     \
	  --enable-cxx-runtime-hack=yes                     \
	  --enable-arm-neon=no --enable-powerpc-vsx=no      \
	    CFLAGS="$(CFLAGS_TEXLIVE_$*)"                   \
	  CPPFLAGS="$(CFLAGS_TEXLIVE_$*)"                   \
	  CXXFLAGS="$(CXXFLAGS_TEXLIVE_$*)"                 \
	LDFLAGS="$(LDFLAGS_TEXLIVE_$*)"                     \
          ac_cv_func_getwd=no ax_cv_c_float_words_bigendian=no ac_cv_namespace_ok=yes
	$(MAKE_$*) -C $(basename $@)
	touch $@	        

build/%/texlive/libs/teckit/libTECkit.a build/%/texlive/libs/harfbuzz/libharfbuzz.a build/%/texlive/libs/graphite2/libgraphite2.a build/%/texlive/libs/libpng/libpng.a build/%/texlive/libs/libpaper/libpaper.a build/%/texlive/libs/zlib/libz.a build/%/texlive/libs/pplib/libpplib.a build/%/texlive/libs/xpdf/libxpdf.a build/%/texlive/libs/zziplib/libzzip.a build/%/texlive/texk/web2c/lib/lib.a: build/%/texlive.configured
	$(MAKE_$*) -C $(dir $@) $(OPTS_$(notdir $(basename $@))_$*) $(OPTS_LIBS_$*)

build/%/texlive/libs/freetype2/libfreetype.a: build/%/texlive.configured
	mkdir -p build/native/texlive/libs/freetype2/ft-build
	$(CC_native) source/texlive/libs/freetype2/freetype-src/src/tools/apinames.c -o build/native/texlive/libs/freetype2/ft-build/apinames
	$(MAKE_$*) -C $(dir $@) $(OPTS_$(notdir $(basename $@))_$*) $(OPTS_LIBS_$*)


build/%/texlive/libs/lua53/.libs/libtexlua53.a build/%/texlive/texk/kpathsea/.libs/libkpathsea.a: build/%/texlive.configured
	$(MAKE_$*) -C $(dir $(abspath $(dir $@)))

build/%/expat/libexpat.a: source/expat.downloaded
	mkdir -p $(dir $@) && cd $(dir $@) &&        \
	$(CMAKE_$*)                                  \
	   -DCMAKE_C_FLAGS="$(CFLAGS_$*_OPT)"        \
	   -DCMAKE_AR="$(shell command -v $(AR_$*))" \
	   -DEXPAT_BUILD_DOCS=off                    \
	   -DEXPAT_SHARED_LIBS=off                   \
	   -DEXPAT_BUILD_EXAMPLES=off                \
	   -DEXPAT_BUILD_FUZZERS=off                 \
	   -DEXPAT_BUILD_TESTS=off                   \
	   -DEXPAT_BUILD_TOOLS=off                   \
	   $(abspath $(basename $<)) 
	$(MAKE_$*) -C $(dir $@)

build/%/fontconfig/src/.libs/libfontconfig.a: source/fontconfig.downloaded build/%/expat/libexpat.a build/%/texlive/libs/freetype2/libfreetype.a
	echo > $(CACHE_FONTCONFIG_$*)
	mkdir -p build/$*/fontconfig
	cd build/$*/fontconfig && \
	$(CONFIGURE_$*) $(abspath $(basename $<)/configure) \
	   --cache-file=$(CACHE_FONTCONFIG_$*)	            \
	   --prefix=$(PREFIX_$*)                            \
	   --host=none-none-none                            \
	   --sysconfdir=/etc                                \
	   --localstatedir=/var                             \
	   --enable-static                                  \
	   --disable-shared                                 \
	   --disable-docs                                   \
	   --with-expat-includes="$(abspath source/expat/lib)" \
	   --with-expat-lib="$(abspath build/$*/expat)"        \
	   CFLAGS="$(CFLAGS_OPT_$*) $(CFLAGS_FONTCONFIG_$*) -v" FREETYPE_CFLAGS="$(addprefix -I$(ROOT)/build/$*/texlive/libs/, freetype2/ freetype2/freetype2/)" FREETYPE_LIBS="-L$(ROOT)/build/$*/texlive/libs/freetype2/ -lfreetype"
	$(MAKE_$*) -C build/$*/fontconfig

build/%/texlive/texk/makeindexk/busytex_makeindex.o: build/%/texlive.configured
	$(MAKE_$*) -C $(dir $@) genind.o mkind.o qsort.o scanid.o scanst.o sortid.o $(OPTS_MAKEINDEX_$*)
	$(call PRELINK,$(dir $@)/*.o,busymain_makeindex)

build/%/texlive/texk/kpathsea/busytex_kpsewhich.o: build/%/texlive.configured
	$(call BUSYTEXIZE,$(dir $@)/kpsewhich.o,busymain_kpsewhich)

build/%/texlive/texk/kpathsea/busytex_kpsestat.o: build/%/texlive.configured
	$(call BUSYTEXIZE,$(dir $@)/kpsestat.o,busymain_kpsestat)

build/%/texlive/texk/kpathsea/busytex_kpseaccess.o: build/%/texlive.configured
	$(call BUSYTEXIZE,$(dir $@)/access.o,busymain_kpseaccess)

build/%/texlive/texk/kpathsea/busytex_kpsereadlink.o: build/%/texlive.configured
	$(call BUSYTEXIZE,$(dir $@)/readlink.o,busymain_kpsereadlink)

build/%/texlive/texk/dvipdfm-x/busytex_xdvipdfmx.o: build/%/texlive.configured
	$(MAKE_$*) -C $(dir $@) $(OPTS_XDVIPDFMX_$*)
	$(call PRELINK,$(dir $@)/*.o,busymain_xdvipdfmx)

build/%/texlive/texk/bibtex-x/busytex_bibtex8.o: build/%/texlive.configured
	$(MAKE_$*) -C $(dir $@) $(OPTS_BIBTEX_$*)
	$(call PRELINK,$(dir $@)/bibtex8-*.o,busymain_bibtex8)

build/%/busytex build/%/busytex.js:
	mkdir -p $(dir $@)
	$(CC_$*)  -o    $(basename $@).o -c busytex.c  $(OPTS_BUSYTEX_COMPILE_$*) $(CFLAGS_OPT_$*)
	$(CXX_$*) -o $@ $(basename $@).o $(addprefix build/$*/texlive/texk/web2c/, $(OBJ_XETEX) $(OBJ_PDFTEX) $(OBJ_LUAHBTEX)) $(addprefix build/$*/, $(OBJ_BIBTEX) $(OBJ_DVIPDF) $(OBJ_DEPS) $(OBJ_MAKEINDEX))  $(addprefix build/$*/texlive/texk/kpathsea/, $(OBJ_KPATHSEA))   $(OPTS_BUSYTEX_LINK_$*)
	tar -cf $(basename $@).tar build/$*/texlive/texk/web2c/*.c

build/%/texlive/libs/icu/icu-build/lib/libicuuc.a build/%/texlive/libs/icu/icu-build/lib/libicudata.a: build/%/texlive.configured
	# WASM build depends on build/native/texlive/libs/icu/icu-build/bin/icupkg build/native/texlive/libs/icu/icu-build/bin/pkgdata
	cd                    build/$*/texlive/libs/icu && $(CONFIGURE_$*) $(abspath source/texlive/libs/icu/configure) $(OPTS_ICU_configure_$*)
	$(MAKE_$*)         -C build/$*/texlive/libs/icu $(OPTS_ICU_configure_make_$*)
	echo "all install:" > build/$*/texlive/libs/icu/icu-build/test/Makefile
	$(MAKE_$*)         -C build/$*/texlive/libs/icu/icu-build $(OPTS_ICU_make_$*) 
	$(MAKE_$*)         -C build/$*/texlive/libs/icu/include/unicode

build/%/texlive/texk/web2c/busytex_libxetex.o: build/%/texlive.configured
	# copying generated C files from native version, since string offsets are off
	mkdir -p $(dir $@)
	# xetexini.c, xetex0.c xetex-pool.c
	-cp $(subst wasm,native,$(dir $@))*.c $(dir $@)
	$(MAKE_$*) -C $(dir $@) synctexdir/xetex-synctex.o xetexdir/xetex-xetexextra.o xetex-xetexini.o xetex-xetex0.o xetex-xetex-pool.o libxetex.a $(OPTS_XETEX_$*)
	$(call PRELINK,$(addprefix $(dir $@),synctexdir/xetex-synctex.o xetexdir/xetex-xetexextra.o xetex-xetexini.o xetex-xetex0.o xetex-xetex-pool.o libxetex.a lib/lib.a),busymain_xetex)

build/%/texlive/texk/web2c/busytex_libpdftex.o: build/%/texlive.configured
	# copying generated C files from native version, since string offsets are off
	mkdir -p $(dir $@)
	# pdftexini.c, pdftex0.c pdftex-pool.c
	-cp $(subst wasm,native,$(dir $@))*.c $(dir $@)
	$(MAKE_$*) -C $(dir $@) pdftexd.h synctexdir/pdftex-synctex.o pdftex-pdftexini.o pdftex-pdftex0.o pdftex-pdftex-pool.o pdftexdir/pdftex-pdftexextra.o libpdftex.a $(OPTS_PDFTEX_$*)
	$(call PRELINK,$(addprefix $(dir $@),synctexdir/pdftex-synctex.o pdftex-pdftexini.o pdftex-pdftex0.o pdftex-pdftex-pool.o pdftexdir/pdftex-pdftexextra.o libpdftex.a lib/lib.a),busymain_pdftex)

build/%/texlive/texk/web2c/busytex_libluahbtex.o: build/%/texlive.configured build/%/texlive/libs/zziplib/libzzip.a build/%/texlive/libs/lua53/.libs/libtexlua53.a
	$(MAKE_$*) -C $(dir $@) luatexdir/luahbtex-luatex.o mplibdir/luahbtex-lmplib.o libluahbtexspecific.a libluaharfbuzz.a libmputil.a libluatex.a $(OPTS_LUAHBTEX_$*)
	$(call PRELINK,$(addprefix $(dir $@),luatexdir/luahbtex-luatex.o mplibdir/luahbtex-lmplib.o libluahbtexspecific.a libluaharfbuzz.a libmputil.a libluatex.a libff.a libluamisc.a libluasocket.a libluaffi.a libmplibcore.a libunilib.a lib/lib.a),busymain_luahbtex)

################################################################################################################

source/texmfrepo.txt:
	mkdir -p source/texmfrepo
	#wget -P source --no-verbose --no-clobber --no-check-certificate $(URL_texlive_full_iso)
	wget -P source --no-verbose --no-clobber --no-check-certificate $(URL_texlive_full_iso_cache) && cat source/*.iso.* > $@.iso && 7z x $@.iso -o$(basename $@)
	#7z x source/texlive.iso -o$(basename $@)
	rm source/*.iso
	find $(basename $@) > $@

build/texlive-basic.profile:
	mkdir -p $(dir $@)
	echo selected_scheme scheme-basic                                   > $@
	echo TEXDIR $(ROOT)/$(basename $@)                                 >> $@ 
	echo TEXMFLOCAL $(ROOT)/$(basename $@)/texmf-dist/texmf-local      >> $@
	echo TEXMFSYSVAR $(ROOT)/$(basename $@)/texmf-dist/texmf-var       >> $@ 
	echo TEXMFSYSCONFIG $(ROOT)/$(basename $@)/texmf-dist/texmf-config >> $@ 
	echo "collection-xetex  1"                                         >> $@ 
	echo "collection-latex  1"                                         >> $@ 
	#echo "collection-latexrecommended  1"                              >> $@ 
	echo "collection-luatex 1"                                         >> $@ 

build/texlive-full.profile:
	mkdir -p $(dir $@)
	echo selected_scheme scheme-full                                    > $@
	echo TEXDIR $(ROOT)/$(basename $@)                                 >> $@ 
	echo TEXMFLOCAL $(ROOT)/$(basename $@)/texmf-dist/texmf-local      >> $@
	echo TEXMFSYSVAR $(ROOT)/$(basename $@)/texmf-dist/texmf-var       >> $@ 
	echo TEXMFSYSCONFIG $(ROOT)/$(basename $@)/texmf-dist/texmf-config >> $@ 
	#echo TEXMFVAR $(ROOT)/$(basename $@)/home/texmf-var >> build/texlive-$*.profile

build/texlive-%.txt: build/texlive-%.profile source/texmfrepo.txt
	$(BUSYTEX_native)
	#
	mkdir -p $(basename $@)/$(BINARCH_native)
	cp $(BUSYTEX_native) $(basename $@)/$(BINARCH_native) 
	#
	$(foreach name,texlive-scripts latexconfig tex-ini-files,tar -xf source/texmfrepo/archive/$(name).r*.tar.xz -C $(basename $@); )
	$(foreach name,xetex luahbtex pdftex xelatex luahblatex pdflatex kpsewhich kpseaccess kpsestat kpsereadlink,printf "#!/bin/sh\n$(ROOT)/$(basename $@)/$(BINARCH_native)/busytex $(name)   $$"@ > $(basename $@)/$(BINARCH_native)/$(name) ; chmod +x $(basename $@)/$(BINARCH_native)/$(name); )
	$(foreach name,mktexlsr.pl updmap-sys.sh updmap.pl fmtutil-sys.sh fmtutil.pl,mv $(basename $@)/texmf-dist/scripts/texlive/$(name) $(basename $@)/$(BINARCH_native)/$(basename $(name)); )
	#
	#mkdir -p $(ROOT)/source/texmfrepotmp  # TMPDIR=$(ROOT)/source/texmfrepotmp 
	TEXLIVE_INSTALL_NO_RESUME=1 $(PERL) source/texmfrepo/install-tl --repository source/texmfrepo --profile build/texlive-$*.profile --custom-bin $(ROOT)/$(basename $@)/$(BINARCH_native)
	# 
	mv $(basename $@)/texmf-dist/texmf-var/web2c/luahbtex/lualatex.fmt $(basename $@)/texmf-dist/texmf-var/web2c/luahbtex/luahblatex.fmt
	##printf "#!/bin/sh\n$(ROOT)/$(basename $@)/$(BINARCH_native)/busytex lualatex   $$"@ > $(basename $@)/$(BINARCH_native)/luahbtex
	##$(basename $@)/$(BINARCH_native)/fmtutil-sys --byengine luahbtex
	echo FINDLOG; cat  $(basename $@)/texmf-dist/texmf-var/web2c/*/*.log                                || true
	echo FINDFMT; ls   $(basename $@)/texmf-dist/texmf-var/web2c/*/*.fmt                                || true
	rm -rf $(addprefix $(basename $@)/, bin readme* tlpkg install* *.html texmf-dist/doc texmf-var/doc) || true
	find $(basename $@)/ -type f -executable -delete || true
	find $(basename $@) > $@
	tar -czf $(basename $@).tar.gz $(basename $@)

################################################################################################################

build/wasm/texlive-%.js: build/texlive-%/texmf-dist build/wasm/fonts.conf 
	mkdir -p $(dir $@)
	echo > build/empty
	echo 'web_user:x:0:0:emscripten:/home/web_user:/bin/false' > build/passwd
	$(PYTHON) $(EMROOT)/tools/file_packager.py $(basename $@).data --js-output=$@ --export-name=BusytexPipeline \
		--lz4 --use-preload-cache \
		--preload build/passwd@/etc/passwd \
		--preload build/empty@/bin/busytex \
		--preload build/wasm/fonts.conf@/etc/fonts/fonts.conf \
		--preload build/texlive-$*@/texlive
	grep -r -I -h 'ProvidesPackage{' build/texlive-$* | grep '^[^%]' | sed -e 's/^/\/\/ /' > $@.providespackage.txt
	cat $@.providespackage.txt $@ > $@.tmp; mv $@.tmp $@

build/wasm/ubuntu-%.js: $(TEXMFFULL)
	mkdir -p $(dir $@)
	$(PYTHON) $(EMROOT)/tools/file_packager.py $(basename $@).data --js-output=$@ --export-name=BusytexPipeline \
		--lz4 --use-preload-cache \
		$(shell $(PYTHON) ubuntu_package_preload.py --package $* --texmf $(TEXMFFULL) --url $(URL_ubuntu_release) --skip-log $@.skip.txt --good-log $@.good.txt --providespackage-log $@.providespackage.txt --ubuntu-log $@.ubuntu.txt)
	-cat $@.providespackage.txt $@ > $@.tmp; mv $@.tmp $@

build/wasm/fonts.conf:
	mkdir -p $(dir $@)
	echo '<?xml version="1.0"?>'                          > $@
	echo '<!DOCTYPE fontconfig SYSTEM "fonts.dtd">'      >> $@
	echo '<fontconfig>'                                  >> $@
	echo '<dir>/texlive/texmf-dist/fonts/opentype</dir>' >> $@
	echo '<dir>/texlive/texmf-dist/fonts/type1</dir>'    >> $@
	echo '</fontconfig>'                                 >> $@

build/native/fonts.conf:
	mkdir -p $(dir $@)
	echo '<?xml version="1.0"?>'                          > $@
	echo '<!DOCTYPE fontconfig SYSTEM "fonts.dtd">'      >> $@
	echo '<fontconfig>'                                  >> $@
	#<dir prefix="relative">../texlive-basic/texmf-dist/fonts/opentype</dir>
	#<dir prefix="relative">../texlive-basic/texmf-dist/fonts/type1</dir>
	#<cachedir prefix="relative">./cache</cachedir>
	echo '</fontconfig>'                                 >> $@

################################################################################################################

.PHONY: build/native/texlivedependencies build/wasm/texlivedependencies
build/native/texlivedependencies build/wasm/texlivedependencies:
	$(MAKE) $(dir $@)expat/libexpat.a
	$(MAKE) $(dir $@)texlive/libs/zziplib/libzzip.a
	$(MAKE) $(dir $@)texlive/libs/libpng/libpng.a 
	$(MAKE) $(dir $@)texlive/libs/libpaper/libpaper.a 
	$(MAKE) $(dir $@)texlive/libs/zlib/libz.a 
	$(MAKE) $(dir $@)texlive/libs/teckit/libTECkit.a 
	$(MAKE) $(dir $@)texlive/libs/harfbuzz/libharfbuzz.a 
	$(MAKE) $(dir $@)texlive/libs/graphite2/libgraphite2.a 
	$(MAKE) $(dir $@)texlive/libs/pplib/libpplib.a 
	$(MAKE) $(dir $@)texlive/libs/lua53/.libs/libtexlua53.a
	$(MAKE) $(dir $@)texlive/libs/freetype2/libfreetype.a 
	$(MAKE) $(dir $@)texlive/libs/xpdf/libxpdf.a
	$(MAKE) $(dir $@)texlive/libs/icu/icu-build/lib/libicuuc.a 
	$(MAKE) $(dir $@)texlive/libs/icu/icu-build/lib/libicudata.a
	$(MAKE) $(dir $@)fontconfig/src/.libs/libfontconfig.a

.PHONY: build/native/busytexapplets build/wasm/busytexapplets
build/native/busytexapplets build/wasm/busytexapplets:
	$(MAKE) $(dir $@)texlive/texk/kpathsea/.libs/libkpathsea.a
	$(MAKE) $(dir $@)texlive/texk/web2c/lib/lib.a
	#
	$(MAKE) $(dir $@)texlive/texk/kpathsea/busytex_kpsewhich.o 
	$(MAKE) $(dir $@)texlive/texk/kpathsea/busytex_kpsestat.o 
	$(MAKE) $(dir $@)texlive/texk/kpathsea/busytex_kpseaccess.o 
	$(MAKE) $(dir $@)texlive/texk/kpathsea/busytex_kpsereadlink.o 
	$(MAKE) $(dir $@)texlive/texk/makeindexk/busytex_makeindex.o
	$(MAKE) $(dir $@)texlive/texk/dvipdfm-x/busytex_xdvipdfmx.o
	$(MAKE) $(dir $@)texlive/texk/bibtex-x/busytex_bibtex8.o
	$(MAKE) $(dir $@)texlive/texk/web2c/busytex_libxetex.o
	$(MAKE) $(dir $@)texlive/texk/web2c/busytex_libpdftex.o
	$(MAKE) $(dir $@)texlive/texk/web2c/busytex_libluahbtex.o

.PHONY: native
native: build/native/fonts.conf
	$(MAKE) build/native/texlive.configured
	$(MAKE) build/native/texlivedependencies
	$(MAKE) build/native/busytexapplets
	$(MAKE) build/native/busytex

.PHONY: wasm
wasm: build/wasm/fonts.conf
	$(MAKE) build/wasm/texlive.configured
	$(MAKE) build/wasm/texlivedependencies
	$(MAKE) build/wasm/busytexapplets
	$(MAKE) build/wasm/busytex.js

################################################################################################################

.PHONY: ubuntu-wasm
ubuntu-wasm: build/wasm/ubuntu-texlive-latex-base.js build/wasm/ubuntu-texlive-latex-extra.js build/wasm/ubuntu-texlive-latex-recommended.js build/wasm/ubuntu-texlive-science.js build/wasm/ubuntu-texlive-fonts-recommended.js build/wasm/ubuntu-texlive-base.js

################################################################################################################

.PHONY: example
example:
	mkdir -p example/assets/large
	echo "console.log('Hello world now')" > example/assets/test.txt
	wget --no-clobber -O example/assets/test.png https://www.google.fr/images/branding/googlelogo/1x/googlelogo_color_272x92dp.png
	wget --no-clobber -O example/assets/test.svg https://upload.wikimedia.org/wikipedia/commons/c/c3/Flag_of_France.svg
	wget --no-clobber -O example/assets/large/test.pdf https://raw.githubusercontent.com/mozilla/pdf.js/ba2edeae/web/compressed.tracemonkey-pldi-09.pdf

build/versions.txt:
	mkdir -p build
	echo 'busytex dependencies:'                                        > $@
	echo texlive: \\url{$(URL_texlive)} \\url{$(URL_texlive_full_iso)} >> $@
	echo ubuntu packages: \\url{$(URL_ubuntu_release)}                 >> $@
	echo expat: \\url{$(URL_expat)}                                    >> $@
	echo fontconfig: \\url{$(URL_fontconfig)}                          >> $@
	echo emscripten: $(EMSCRIPTEN_VERSION)                             >> $@

.PHONY: smoke-native
smoke-native: build/native/busytex
	-$(LDD_native) $(BUSYTEX_native)
	$(BUSYTEX_native)
	$(foreach applet,xelatex pdflatex luahblatex lualatex bibtex8 xdvipdfmx kpsewhich kpsestat kpseaccess kpsereadlink,echo $(BUSYTEX_native) $(applet) --version; $(BUSYTEX_native) $(applet) --version; )

################################################################################################################

.PHONY: clean-tds
clean-tds:
	rm -rf build/texlive-*

.PHONY: clean-native
clean-native:
	rm -rf build/native

.PHONY: clean-wasm
clean-wasm:
	rm -rf build/wasm

.PHONY: clean_build
clean-build:
	rm -rf build

.PHONY: clean-dist
clean-dist:
	rm -rf dist-*

.PHONY: clean-example
clean-example:
	rm -rf example/*.aux example/*.bbl example/*.blg example/*.log example/*.xdv

.PHONY: clean
clean:
	rm -rf build source

################################################################################################################

.PHONY: dist-wasm
dist-wasm:
	mkdir -p $@
	-cp build/wasm/busytex.js       build/wasm/busytex.wasm       $@ 
	-cp build/wasm/texlive-basic.js build/wasm/texlive-basic.data $@ 
	-cp build/wasm/ubuntu-*.js      build/wasm/ubuntu-*.data      $@ 

.PHONY: dist-native
dist-native: build/native/busytex build/native/fonts.conf
	mkdir -p dist-native
	cp $(addprefix build/native/, busytex fonts.conf) dist-native
	#  luahbtex/lualatex.fmt
	cp $(addprefix build/texlive-basic/texmf-dist/texmf-var/web2c/, pdftex/pdflatex.fmt xetex/xelatex.fmt luahbtex/luahblatex.fmt) dist-native
	cp -r build/texlive-basic dist-native/texlive

.PHONY: dist-native-full
dist-native-full: build/native/busytex build/native/fonts.conf
	mkdir -p dist-native
	cp $(addprefix build/native/, busytex fonts.conf) dist-native
	cp $(addprefix build/texlive-full/texmf-dist/texmf-var/web2c/, pdftex/pdflatex.fmt xetex/xelatex.fmt luahbtex/luahblatex.fmt) dist-native
	ln -s $(ROOT)/build/texlive-full dist-native/texlive

.PHONY: download-native
download-native:
	mkdir -p source build/native build/native/texlive/texk/web2c/web2c
	wget  -P build/native                                 -nc $(addprefix $(URLRELEASE)/,$(BUSYTEX_BIN) busytex.tar)
	wget  -P build/native/texlive/texk/web2c              -nc $(addprefix $(URLRELEASE)/,$(BUSYTEX_TEXBIN))
	wget  -P build/native/texlive/texk/web2c/web2c        -nc $(addprefix $(URLRELEASE)/,$(BUSYTEX_WEB2CBIN))
	chown $(shell whoami) $(BUSYTEX_native) $(BUSYWEB2C_native); chmod +x  $(BUSYWEB2C_native) $(BUSYTEX_native); file $(BUSYWEB2C_native) $(BUSYTEX_native); $(BUSYTEX_native);
	chown $(shell whoami) $(addprefix build/native/texlive/texk/web2c/,$(BUSYTEX_TEXBIN)) $(addprefix build/native/texlive/texk/web2c/web2c/,$(BUSYTEX_WEB2CBIN)); chmod +x $(addprefix build/native/texlive/texk/web2c/,$(BUSYTEX_TEXBIN)) $(addprefix build/native/texlive/texk/web2c/web2c/,$(BUSYTEX_WEB2CBIN)); file $(addprefix build/native/texlive/texk/web2c/,$(BUSYTEX_TEXBIN)) $(addprefix build/native/texlive/texk/web2c/web2c/,$(BUSYTEX_WEB2CBIN))
	#
	mkdir -p build/native build/native/texlive/libs/icu/icu-build/bin build/native/texlive/libs/freetype2/ft-build build/native/texlive/texk/web2c/web2c
	-rm build/native/texlive/libs/icu/icu-build/bin/icupkg build/native/texlive/libs/icu/icu-build/bin/pkgdata build/native/texlive/libs/freetype2/ft-build/apinames
	-ln -s $(shell which icupkg)  build/native/texlive/libs/icu/icu-build/bin/
	-ln -s $(shell which pkgdata) build/native/texlive/libs/icu/icu-build/bin/
	#-$(CC_native) source/texlive/libs/freetype2/freetype-src/src/tools/apinames.c -o build/native/texlive/libs/freetype2/ft-build/apinames
	chmod +x $(addprefix build/native/texlive/texk/web2c/, $(BUSYTEX_TEXBIN)) $(addprefix build/native/texlive/texk/web2c/web2c/, $(BUSYTEX_WEB2CBIN))

