mkdir -p installer && curl -L https://mirror.ctan.org/systems/texlive/tlnet/install-tl-unx.tar.gz | tar -xzf - -C installer --strip-components 1
curl -O https://github.com/busytex/busytex/releases/download/build_native_9b40c3ce65d39b52bc38eb4794b8f9837b956064_12299351715_1/busytex

BINARCH_native=bin/_custom

mkdir -p $(basename $@)/$BINARCH_native
cp $(BUSYTEX_native) $(basename $@)/$BINARCH_native

for name in xetex luahbtex pdftex xelatex luahblatex pdflatex kpsewhich kpseaccess kpsestat kpsereadlink; do
    printf "#!/bin/sh\n$(ROOT)/$(basename $@)/$BINARCH_native/busytex $name   $$"@ > $(basename $@)/$BINARCH_native/$name
    chmod +x $(basename $@)/$BINARCH_native/$name
done
for name in mktexlsr.pl updmap-sys.sh updmap.pl fmtutil-sys.sh fmtutil.pl; do
    mv $(basename $@)/texmf-dist/scripts/texlive/$name $(basename $@)/$BINARCH_native/$(basename $name)
done

echo selected_scheme scheme-basic                                  > texlive-dist.profile
echo TEXDIR $(ROOT)/$(basename $@)                                 >> texlive-dist.profile 
echo TEXMFLOCAL $(ROOT)/$(basename $@)/texmf-dist/texmf-local      >> texlive-dist.profile 
echo TEXMFSYSVAR $(ROOT)/$(basename $@)/texmf-dist/texmf-var       >> texlive-dist.profile  
echo TEXMFSYSCONFIG $(ROOT)/$(basename $@)/texmf-dist/texmf-config >> texlive-dist.profile  
echo "collection-xetex  1"                                         >> texlive-dist.profile  
echo "collection-latex  1"                                         >> texlive-dist.profile  
echo "collection-luatex 1"                                         >> texlive-dist.profile  

TEXLIVE_INSTALL_NO_RESUME=1 perl installer/install-tl --repository source/texmfrepo --profile texlive-dist.profile --custom-bin $(ROOT)/$(basename $@)/$BINARCH_native --no-doc-install --no-src-install
echo '<?xml version="1.0"?><!DOCTYPE fontconfig SYSTEM "fonts.dtd"><fontconfig><dir>/texlive/texmf-dist/fonts/opentype</dir><dir>/texlive/texmf-dist/fonts/type1</dir></fontconfig>' > $(basename $@)/fonts.conf

#mv $(basename $@)/texmf-dist/texmf-var/web2c/luahbtex/lualatex.fmt $(basename $@)/texmf-dist/texmf-var/web2c/luahbtex/luahblatex.fmt
