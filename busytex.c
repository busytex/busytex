#define _GNU_SOURCE
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <sys/stat.h>

#ifdef __cplusplus
#define extern  extern "C"
#endif

extern int optind;
extern char **environ;

#ifdef BUSYTEX_PDFTEX 
extern int busymain_pdftex(int argc, char* argv[]);
#endif
#ifdef BUSYTEX_LUATEX
//extern "C" int busymain_luatex(int argc, char* argv[]);
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

void flush_streams()
{
    fputc('\n', stdout);
    fputc('\n', stderr);
    fflush(NULL);
}

void putenvjoin(const char* name, const char* value)
{
    enum {putenvjoinsize = 65536};
    static char tmp[putenvjoinsize];
    const char* cur = getenv(name);
    snprintf(tmp, putenvjoinsize, (cur == NULL || cur[0] == '\0') ? "%s=%s" : "%s=%s:%s", name, value, cur);
    putenv(tmp);
}

int main(int argc, char* argv[])
{
    /*fprintf(stderr, "BEGINBUSYTEX\n");
    for(int i = 0; i < argc; i++)
        fprintf(stderr, "%s ", argv[i]);
    fprintf(stderr, "\n");
    for(int i = 0; environ[i] != NULL; i++)
        fprintf(stderr, "%s\n", environ[i]);
    fprintf(stderr, "\nENDBUSYTEX\n");*/

    struct stat statbuf;

    if(getenv("TEXMFDIST") == NULL && stat("/texlive/", &statbuf) == 0)
    {
        putenvjoin("TEXMFDIST", "/texlive/texmf-dist");
        putenvjoin("TEXMFVAR",  "/texlive/texmf-dist/texmf-var");
        putenvjoin("TEXMFCNF",  "/texlive/texmf-dist/web2c");
        putenvjoin("FONTCONFIG_PATH", "/texlive/");
        //putenv("PDFLATEXFMT=/texlive/texmf-dist/texmf-var/web2c/pdftex/pdflatex.fmt");
    }

    if(argc < 2)
    {
        fprintf(stderr, "busytex: '%s' %d\n", getenv("TEXMFDIST"), (int)stat("/texlive/", &statbuf));

        printf("\n"
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
    if(0 == strcmp("pdftex", argv[1]) || 0 == strcmp("pdflatex", argv[1]))     { argv[1] = argv[0]; optind = 1; return busymain_pdftex  (argc - 1, argv + 1); }
#endif
#ifdef BUSYTEX_LUATEX
    // luatex, lualatex
    if(0 == strcmp("luahbtex", argv[1]) || 0 == strcmp("luahblatex", argv[1])) { argv[1] = argv[0]; optind = 1; return busymain_luahbtex(argc - 1, argv + 1); }
#endif
#ifdef BUSYTEX_XETEX
    if(0 == strcmp("xetex", argv[1]) || 0 == strcmp("xelatex", argv[1]))       { argv[1] = argv[0]; optind = 1; return busymain_xetex   (argc - 1, argv + 1); }
#endif
#ifdef BUSYTEX_XDVIPDFMX
    if(0 == strcmp("xdvipdfmx", argv[1]))    { argv[1] = argv[0]; optind = 1; return busymain_xdvipdfmx   (argc - 1, argv + 1); }
#endif
#ifdef BUSYTEX_BIBTEX8
    if(0 == strcmp("bibtex8", argv[1]))      { argv[1] = argv[0]; optind = 1; return busymain_bibtex8     (argc - 1, argv + 1); }
#endif
#ifdef BUSYTEX_MAKEINDEX
    if(0 == strcmp("makeindex", argv[1]))    { argv[1] = argv[0]; optind = 1; return busymain_makeindex   (argc - 1, argv + 1); }
#endif
#ifdef BUSYTEX_KPSE
    if(0 == strcmp("kpsewhich", argv[1]))    { argv[1] = argv[0]; optind = 1; return busymain_kpsewhich   (argc - 1, argv + 1); }
    if(0 == strcmp("kpsestat", argv[1]))     { argv[1] = argv[0]; optind = 1; return busymain_kpsestat    (argc - 1, argv + 1); }
    if(0 == strcmp("kpseaccess", argv[1]))   { argv[1] = argv[0]; optind = 1; return busymain_kpseaccess  (argc - 1, argv + 1); }
    if(0 == strcmp("kpsereadlink", argv[1])) { argv[1] = argv[0]; optind = 1; return busymain_kpsereadlink(argc - 1, argv + 1); }
#endif
    return 1;
}
