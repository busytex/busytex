curl -O https://github.com/busytex/busytex/releases/download/build_native_9b40c3ce65d39b52bc38eb4794b8f9837b956064_12299351715_1/busytex
mkdir -p installer && curl -L https://mirror.ctan.org/systems/texlive/tlnet/install-tl-unx.tar.gz | tar -xzf - -C installer --strip-components 1

BUSYTEX_native=busytex
BINARCH_native=bin/_custom
DIST=texlive-dist
TEXDIR=$PWD/$DIST

mkdir -p $DIST/$BINARCH_native
cp $BUSYTEX_native $DIST/$BINARCH_native

for name in xetex luahbtex pdftex xelatex luahblatex pdflatex kpsewhich kpseaccess kpsestat kpsereadlink; do
    printf "#!/bin/sh\n$DIST/$BINARCH_native/busytex $name $$"@ > $DIST/$BINARCH_native/$name
    chmod +x $DIST/$BINARCH_native/$name
done
for name in updmap.pl fmtutil.pl mktexlsr.pl; do
    mv $DIST/texmf-dist/scripts/texlive/$name $DIST/$BINARCH_native/${name%.*}
done

echo selected_scheme scheme-basic                    > $DIST.profile
echo TEXDIR $TEXDIR                                 >> $DIST.profile 
echo TEXMFLOCAL $TEXDIR/texmf-dist/texmf-local      >> $DIST.profile 
echo TEXMFSYSVAR $TEXDIR/texmf-dist/texmf-var       >> $DIST.profile  
echo TEXMFSYSCONFIG $TEXDIR/texmf-dist/texmf-config >> $DIST.profile  
echo "collection-xetex  1"                          >> $DIST.profile  
echo "collection-latex  1"                          >> $DIST.profile  
echo "collection-luatex 1"                          >> $DIST.profile  

TEXLIVE_INSTALL_NO_RESUME=1 perl installer/install-tl --repository source/texmfrepo --profile $DIST.profile --custom-bin $TEXDIR/$BINARCH_native --no-doc-install --no-src-install
echo '<?xml version="1.0"?><!DOCTYPE fontconfig SYSTEM "fonts.dtd"><fontconfig><dir>/texlive/texmf-dist/fonts/opentype</dir><dir>/texlive/texmf-dist/fonts/type1</dir></fontconfig>' > $DIST/fonts.conf

#mv $(basename $@)/texmf-dist/texmf-var/web2c/luahbtex/lualatex.fmt $(basename $@)/texmf-dist/texmf-var/web2c/luahbtex/luahblatex.fmt
