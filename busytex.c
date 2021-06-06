#include <string.h>

extern int optind;

#ifdef BUSYTEX_PDFTEX
extern int busymain_pdftex(int argc, char* argv[]);
#endif

#ifdef BUSYTEX_LUATEX
extern int busymain_luatex(int argc, char* argv[]);
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

#ifdef BUSYTEX_KPSEWHICH
extern int busymain_kpsewhich(int argc, char* argv[]);
#endif

#ifdef BUSYTEX_MKAEINDEX
extern int busymain_makeindex(int argc, char* argv[]);
#endif

int main(int argc, char* argv[])
{
    if(argc < 2)
        return 0;

#ifdef BUSYTEX_PDFTEX
    if(strcmp("pdftex", argv[1]) == 0 || strcmp("pdflatex", argv[1]) == 0)
    {
        argv[1] = argv[0];
        optind = 1;
        return busymain_pdftex(argc - 1, argv + 1);
    }
#endif

#ifdef BUSYTEX_LUATEX
    if(strcmp("luatex", argv[1]) == 0 || strcmp("lualatex", argv[1]) == 0)
    {
        argv[1] = argv[0];
        optind = 1;
        return busymain_luatex(argc - 1, argv + 1);
    }
#endif

#ifdef BUSYTEX_XETEX
    if(strcmp("xetex", argv[1]) == 0 || strcmp("xelatex", argv[1]) == 0)
    {
        argv[1] = argv[0];
        optind = 1;
        return busymain_xetex(argc - 1, argv + 1);
    }
#endif
    
#ifdef BUSYTEX_XDVIPDFMX
    if(strcmp("xdvipdfmx", argv[1]) == 0)
    {
        argv[1] = argv[0];
        optind = 1;
        return busymain_xdvipdfmx(argc - 1, argv + 1);
    }
#endif
    
#ifdef BUSYTEX_BIBTEX8
    if(strcmp("bibtex8", argv[1]) == 0)
    {
        argv[1] = argv[0];
        optind = 1;
        return busymain_bibtex8(argc - 1, argv + 1);
    }
#endif

#ifdef BUSYTEX_KPSEWHICH
    if(strcmp("kpsewhich", argv[1]) == 0)
    {
        argv[1] = argv[0];
        optind = 1;
        return busymain_kpsewhich(argc - 1, argv + 1);
    }
#endif

#ifdef BUSYTEX_MAKEINDEX
    if(strcmp("makeindex", argv[1]) == 0)
    {
        argv[1] = argv[0];
        optind = 1;
        return busymain_makeindex(argc - 1, argv + 1);
    }
#endif

    return 0;
}
