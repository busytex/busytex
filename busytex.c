#define _GNU_SOURCE
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

#include <unistd.h>
#include <errno.h>
#include <string.h>
#include <dlfcn.h>
#include <fcntl.h>
#include <stdarg.h>

#include <EXTERN.h>
#include <perl.h>
#include <XSUB.h>

extern char _binary_fmtutil_pl_start[];
extern char _binary_fmtutil_pl_end[];
extern char _binary_updmap_pl_start[];
extern char _binary_updmap_pl_end[];
extern char _binary_pack_perl_modules_pl_start[];
extern char _binary_pack_perl_modules_pl_end[];

extern void boot_Fcntl      (pTHX_ CV* cv);
extern void boot_IO         (pTHX_ CV* cv);
extern void boot_DynaLoader (pTHX_ CV* cv);

void xs_init                (pTHX)
{
    static const char file[] = __FILE__;
    dXSUB_SYS;
    PERL_UNUSED_CONTEXT;

    newXS("Fcntl::bootstrap", boot_Fcntl, file);
    newXS("IO::bootstrap", boot_IO, file);
    newXS("DynaLoader::boot_DynaLoader", boot_DynaLoader, file);
}

int busymain_fmtutil(int argc, char* argv[])
{
    //PERL_SYS_INIT3(&argc, &argv, &env);
    puts("1");
    PERL_SYS_INIT3((int *)NULL,(char ***)NULL,(char ***)NULL);
    puts("11");
    PerlInterpreter* my_perl = perl_alloc();
    puts("12");
    perl_construct(my_perl);
    PL_exit_flags |= PERL_EXIT_DESTRUCT_END;

    puts("2");
    static char script[1 << 20];
    static char* my_args[1 << 10] = {"my_perl", "-e", NULL, "--", "--sys"};
    int my_argc = 5;
    
    int iSize =  (int)(_binary_pack_perl_modules_pl_end - _binary_pack_perl_modules_pl_start);
    strncpy(script,    _binary_pack_perl_modules_pl_start, iSize);
    script[iSize] = '\0';
    iSize =  (int)(_binary_fmtutil_pl_end - _binary_fmtutil_pl_start);
    strncat(script,    _binary_fmtutil_pl_start, iSize);

    puts("3");
    my_args[2] = script;
    memcpy(my_args + my_argc, argv + 1, (argc - 1) * sizeof(char*));
    my_argc += (argc - 1);
    puts("4");
    perl_parse(my_perl, xs_init, my_argc, my_args, (char **)NULL);
    puts("5");
    perl_run(my_perl);
    perl_destruct(my_perl);
    perl_free(my_perl);
    PERL_SYS_TERM();

    return 0;
}

int busymain_updmap(int argc, char* argv[])
{
    //PERL_SYS_INIT3(&argc, &argv, &env);
    PERL_SYS_INIT3((int *)NULL,(char ***)NULL,(char ***)NULL);
    PerlInterpreter* my_perl = perl_alloc();
    perl_construct(my_perl);
    PL_exit_flags |= PERL_EXIT_DESTRUCT_END;
    
    static char script[1 << 20];
    static char* my_args[1 << 10] = {"my_perl", "-e", NULL, "--", "--sys"};
    int my_argc = 5;
    
    int iSize =  (int)(_binary_pack_perl_modules_pl_end - _binary_pack_perl_modules_pl_start);
    strncpy(script,    _binary_pack_perl_modules_pl_start, iSize);
    script[iSize] = '\0';
    iSize =  (int)(_binary_updmap_pl_end - _binary_updmap_pl_start);
    strncat(script,    _binary_updmap_pl_start, iSize);

    my_args[2] = script;
    memcpy(my_args + my_argc, argv + 1, (argc - 1) * sizeof(char*));
    my_argc += (argc - 1);

    perl_parse(my_perl, xs_init, my_argc, my_args, (char **)NULL);
    
    perl_run(my_perl);
    perl_destruct(my_perl);
    perl_free(my_perl);
    PERL_SYS_TERM();

    return 0;
}


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
#ifdef BUSYTEX_FMTUTILUPDMAP
            "fmtutil-sys\n"
            "updmap-sys\n"
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
    APPLET(fmtutil, fmtutil-sys)
    APPLET(updmap, updmap-sys)
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
