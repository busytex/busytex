set -ex

# rm -rf texlive-dist

DIST=texlive-dist
BUSYTEX_native=busytex
BINARCH_native=bin/_custom
TEXDIR=$PWD/$DIST

mkdir -p $DIST/$BINARCH_native && curl -o $DIST/$BINARCH_native/$BUSYTEX_native -L https://github.com/busytex/busytex/releases/download/build_native_9b40c3ce65d39b52bc38eb4794b8f9837b956064_12299351715_1/busytex && chmod +x $DIST/$BINARCH_native/$BUSYTEX_native && ln -s $TEXDIR/$BINARCH_native/$BUSYTEX_native $BUSYTEX_native
# https://github.com/busytex/busytex/releases/download/texlive2023-20230313.iso/install-tl-unx.tar.gz
mkdir -p $DIST/installer && curl -L https://github.com/busytex/busytex/releases/download/texlive2023-20230313.iso/install-tl-unx.tar.gz    | tar -xzf - --strip-components=1             -C $DIST/installer 
# https://mirror.ctan.org/systems/texlive/tlnet/archive/latexconfig.r68923.tar.xz
curl --output-dir $DIST -O -L https://github.com/busytex/busytex/releases/download/texlive2023-20230313.iso/latexconfig.r68923.tar.xz     && tar -xf $DIST/latexconfig.r68923.tar.xz     -C $DIST
# https://mirror.ctan.org/systems/texlive/tlnet/archive/tex-ini-files.r68920.tar.xz
curl --output-dir $DIST -O -L https://github.com/busytex/busytex/releases/download/texlive2023-20230313.iso/tex-ini-files.r68920.tar.xz   && tar -xf $DIST/tex-ini-files.r68920.tar.xz   -C $DIST
# https://mirror.ctan.org/systems/texlive/tlnet/archive/texlive-scripts.r73538.tar.xz
curl --output-dir $DIST -O -L https://github.com/busytex/busytex/releases/download/texlive2023-20230313.iso/texlive-scripts.r73538.tar.xz && tar -xf $DIST/texlive-scripts.r73538.tar.xz -C $DIST
for name in xetex luahbtex pdftex xelatex luahblatex pdflatex kpsewhich kpseaccess kpsestat kpsereadlink; do printf "#!/bin/sh\n$TEXDIR/$BINARCH_native/busytex $name \$@" > $DIST/$BINARCH_native/$name && chmod +x $DIST/$BINARCH_native/$name; done
for name in updmap.pl fmtutil.pl mktexlsr.pl updmap-sys.sh updmap-user.sh fmtutil-sys.sh fmtutil-user.sh; do cp $DIST/texmf-dist/scripts/texlive/$name $DIST/$BINARCH_native/${name%.*} ; done


echo selected_scheme scheme-basic                    > $DIST/$DIST.profile
echo TEXDIR $TEXDIR                                 >> $DIST/$DIST.profile 
echo TEXMFLOCAL $TEXDIR/texmf-dist/texmf-local      >> $DIST/$DIST.profile 
echo TEXMFSYSVAR $TEXDIR/texmf-dist/texmf-var       >> $DIST/$DIST.profile  
echo TEXMFSYSCONFIG $TEXDIR/texmf-dist/texmf-config >> $DIST/$DIST.profile  
echo "collection-xetex  1"                          >> $DIST/$DIST.profile  
echo "collection-latex  1"                          >> $DIST/$DIST.profile  
echo "collection-luatex 1"                          >> $DIST/$DIST.profile  
TEXLIVE_INSTALL_NO_RESUME=1 perl $DIST/installer/install-tl --profile $DIST/$DIST.profile --custom-bin $TEXDIR/$BINARCH_native --no-doc-install --no-src-install --no-interaction
echo '<?xml version="1.0"?><!DOCTYPE fontconfig SYSTEM "fonts.dtd"><fontconfig><dir>/texlive/texmf-dist/fonts/opentype</dir><dir>/texlive/texmf-dist/fonts/type1</dir></fontconfig>' > $DIST/fonts.conf
find $DIST -name '*.fmt'
cp $DIST/texmf-dist/texmf-var/web2c/luahbtex/lualatex.fmt $DIST/texmf-dist/texmf-var/web2c/luahbtex/luahblatex.fmt
