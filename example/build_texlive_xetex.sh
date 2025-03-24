# http://www.linuxfromscratch.org/blfs/view/svn/pst/texlive.html
# https://www.tug.org/texlive/build.html
# https://www.tug.org/texlive/doc/tlbuild.html#Build-one-engine

# ./prefix/bin/xelatex --fmt=latex_format/base/latex.fmt test.tex

export MAKEFLAGS=-j20

TEXLIVE_TEXMF_URL=ftp://tug.org/texlive/historic/2020/texlive-20200406-texmf.tar.xz
TEXLIVE_SOURCE_URL=ftp://tug.org/texlive/historic/2020/texlive-20200406-source.tar.xz
TEXLIVE_TLPDB_URL=ftp://tug.org/texlive/historic/2020/texlive-20200406-tlpdb-full.tar.gz
TEXLIVE_BASE_URL=http://mirrors.ctan.org/macros/latex/base.zip
TEXLIVE_INSTALLER_URL=http://mirror.ctan.org/systems/texlive/tlnet/install-tl-unx.tar.gz
TEXLIVE_SOURCE_DIR=$PWD/texlive-20200406-source

ROOT=$PWD
TEXLIVE=$PWD/texlive
PREFIX=$PWD/prefix
CACHE=$PWD/config.cache
XELATEX_EXE=$PREFIX/bin/xelatex
XETEX_EXE=$PREFIX/bin/xetex
mkdir -p $PREFIX

wget --no-clobber $TEXLIVE_SOURCE_URL
tar -xvf $(basename $TEXLIVE_SOURCE_URL)
cd $TEXLIVE_SOURCE_DIR
mkdir -p texlive-build
cd texlive-build


#  --disable-dvipng                                 \
#  --disable-dvisvgm                            \
#  --disable-dvi2tty                            \
#  --disable-luatex                              \
#  --disable-luajittex                           \
#  --disable-luahbtex                            \
#  --disable-luajithbtex                         \
#  --disable-mflua                               \
#  --disable-mfluajit                            \
#  --disable-etex                               \
#  --disable-detex                              \
#  --disable-lcdf-typetools                         \
#  --disable-ps2eps                                 \
#  --disable-psutils                            \
#  --disable-t1utils                            \
#  --disable-texinfo                            \
#  --disable-xindy                              \
#  --disable-biber                              \

../configure                                    \
  --cache-file=$CACHE                           \
  --prefix=$PREFIX                              \
  --enable-static                               \
  --enable-xetex                                \
  --enable-dvipdfm-x                            \
  --disable-shared                              \
  --disable-multiplatform                       \
  --disable-native-texlive-build                \
  --disable-all-pkgs                            \
  --without-x                                   \
  --without-system-cairo                        \
  --without-system-gmp                          \
  --without-system-graphite2                    \
  --without-system-harfbuzz                     \
  --without-system-libgs                        \
  --without-system-libpaper                     \
  --without-system-mpfr                         \
  --without-system-pixman                       \
  --without-system-poppler                      \
  --without-system-xpdf                         \
  --without-system-icu                          \
  --without-system-fontconfig                   \
  --without-system-freetype2                    \
  --without-system-libpng                       \
  --without-system-zlib                         \
  --with-banner-add=" - BLFS"

make $MAKEFLAGS
make $MAKEFLAGS install
cd texk/web2c
make $MAKEFLAGS xetex
cp xetex $XETEX_EXE
cp $XETEX_EXE $XELATEX_EXE

cd $ROOT
mkdir -p $TEXLIVE
echo selected_scheme scheme-basic > $TEXLIVE/profile.input
echo TEXDIR $TEXLIVE >> $TEXLIVE/profile.input
echo TEXMFLOCAL $TEXLIVE/texmf-local >> $TEXLIVE/profile.input
echo TEXMFSYSVAR $TEXLIVE/texmf-var >> $TEXLIVE/profile.input
echo TEXMFSYSCONFIG $TEXLIVE/texmf-config >> $TEXLIVE/profile.input
echo TEXMFVAR $PWD/home/texmf-var >> $TEXLIVE/profile.input
wget --no-clobber $TEXLIVE_INSTALLER_URL
cd $TEXLIVE
tar xzvf ../install-tl-unx.tar.gz
./install-tl-*/install-tl -profile $TEXLIVE/profile.input
rm -rf bin readme* tlpkg install* *.html texmf-dist/doc texmf-var/web2c

cd $ROOT
export TEXMFDIST=$PWD/texlive/texmf-dist
wget --no-clobber $TEXLIVE_BASE_URL
mkdir -p latex_format
cd latex_format
unzip -o ../base.zip
cd base
$XELATEX_EXE -ini -etex unpack.ins
touch hyphen.cfg
$XELATEX_EXE -ini -etex latex.ltx
                                                                            