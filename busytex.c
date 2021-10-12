#include <stdio.h>
#include <string.h>

#define concat2(X, Y) X ## Y
#define concat(X, Y) concat2(X, Y)
#define busymain(x) concat(busymain_, x)

//#define busymain(x) (busymain_##x)

#define APPLET(name1, name2) { if(strcmp(#name1, argv[1]) == 0 || strcmp(#name2, argv[1]) == 0)   { argv[1] = argv[0]; optind = 1; return busymain(name1)(argc - 1, argv + 1); } }

extern int optind;

#ifdef BUSYTEX_PDFTEX 
extern int busymain_pdftex(int argc, char* argv[]);
#endif
#ifdef BUSYTEX_LUATEX
//extern int busymain_luatex(int argc, char* argv[]);
extern int busymain_luahbtex(int argc, char* argv[]);
#endif
#ifdef BUSYTEX_XETEX
extern int busymain_xetex(int argc, char* argv[]);
#endif
#ifdef BUSYTEX_XDVIPDFMX
extern int busymain_xdvipdfmx(int argc, char* argv[]);
#endif
#ifdef BUSYTEX_BIBTEX8
extern int busymain_bibtex8(int argc, char* argv[]);
#endif
#ifdef BUSYTEX_MAKEINDEX
extern int busymain_makeindex(int argc, char* argv[]);
#endif
#ifdef BUSYTEX_KPSE
extern int busymain_kpsewhich(int argc, char* argv[]);
extern int busymain_kpsestat(int argc, char* argv[]);
extern int busymain_kpseaccess(int argc, char* argv[]);
extern int busymain_kpsereadlink(int argc, char* argv[]);
#endif

#ifdef BUSYTEX_FMTUTILUPDMAP
extern int busymain_fmtutil(int argc, char* argv[]);
extern int busymain_updmap(int argc, char* argv[]);
#endif

void flush_streams()
{
    fputc('\n', stdout);
    fputc('\n', stderr);
    fflush(NULL);
}

int main(int argc, char* argv[])
{
    if(argc < 2)
    {
        printf(
#ifdef BUSYTEX_PDFTEX
            "pdftex\n"
#endif
#ifdef BUSYTEX_LUATEX
            "luatex\n"
            "luahbtex\n"
#endif
#ifdef BUSYTEX_XETEX
            "xetex\n"
#endif
#ifdef BUSYTEX_XDVIPDFMX
            "xdvipdfmx\n"
#endif
#ifdef BUSYTEX_BIBTEX8
            "bibtex8\n"
#endif
#ifdef BUSYTEX_MAKEINDEX
            "makeindex\n"
#endif
#ifdef BUSYTEX_KPSE
            "kpsewhich\n"
            "kpsestat\n"
            "kpseaccess\n"
            "kpsereadlink\n"
#endif
        );
        return 0;
    }

#ifdef BUSYTEX_PDFTEX
    APPLET(pdftex, pdflatex)
#endif
//    APPLET(luatex, lualatex)
#ifdef BUSYTEX_LUATEX
    APPLET(luahbtex, luahblatex)
#endif
#ifdef BUSYTEX_XETEX
    APPLET(xetex, xelatex)
#endif
#ifdef BUSYTEX_XDVIPDFMX
    APPLET(xdvipdfmx, xdvipdfmx)
#endif
#ifdef BUSYTEX_BIBTEX8
    APPLET(bibtex8, bibtex8)
#endif
#ifdef BUSYTEX_MAKEINDEX
    APPLET(makeindex, makeindex)
#endif
#ifdef BUSYTEX_KPSE
    APPLET(kpsewhich, kpsewhich)
    APPLET(kpsestat, kpsestat)
    APPLET(kpseaccess, kpseaccess)
    APPLET(kpsereadlink, kpsereadlink)
#endif
#ifdef BUSYTEX_FMTUTILUPDMAP
    APPLET(fmtutil, fmtutil)
    APPLET(updmap, updmap)
#endif
#ifdef BUSYTEX_TEXBIN
    APPLET(ctangle, ctangle)
    APPLET(otangle, otangle)
    APPLET(tangle, tangle)
    APPLET(tangleboot, tangleboot)
    APPLET(ctangleboot, ctangleboot)
    APPLET(tie, tie)
    APPLET(fixwrites, fixwrites)
    APPLET(makecpool, makecpool)
    APPLET(splitup, splitup)
    APPLET(web2c, web2c)
#endif
    return 1;
}
