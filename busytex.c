#include <string.h>

extern int optind;

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

int main(int argc, char* argv[])
{
    if(argc < 2)
        return 0;

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

    return 0;
}
