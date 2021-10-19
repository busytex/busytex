#define _GNU_SOURCE

#include <stdio.h>
#include <unistd.h>
#include <errno.h>
#include <string.h>
#include <dlfcn.h>
#include <fcntl.h>
#include <stdarg.h>

#include <EXTERN.h>
#include <perl.h>
#include <XSUB.h>

//#include "preload.c"

///////////////////////////////////////
// #include <xsinit.c>

extern void boot_Fcntl      (pTHX_ CV* cv);
extern void boot_IO         (pTHX_ CV* cv);
extern void boot_DynaLoader (pTHX_ CV* cv);

//EXTERN_C void xs_init         (pTHX);
//EXTERN_C 
void xs_init         (pTHX)
{
    static const char file[] = __FILE__;
    dXSUB_SYS;
    PERL_UNUSED_CONTEXT;

    newXS("Fcntl::bootstrap", boot_Fcntl, file);
    newXS("IO::bootstrap", boot_IO, file);
    newXS("DynaLoader::boot_DynaLoader", boot_DynaLoader, file);
}
///////////////////////////////////////


static char script[1 << 20];

extern char _binary_fmtutil_pl_start[];
extern char _binary_fmtutil_pl_end[];


int main(int argc, char **argv, char **env)
{
    PERL_SYS_INIT3(&argc, &argv, NULL);
    //PerlInterpreter* my_perl = perl_alloc();
    //perl_construct(my_perl);
    //PL_exit_flags |= PERL_EXIT_DESTRUCT_END;
    //
    ////perl_parse(my_perl, xs_init, argc, argv, (char **)NULL);
    //
    //int iSize =  (int)(_binary_fmtutil_pl_end - _binary_fmtutil_pl_start);
    //strncpy(script,    _binary_fmtutil_pl_start, iSize);
    //script[iSize] = '\0';

    //char *one_args[] = { "my_perl", "-e", script, "--", argv[1], NULL };
    //perl_parse(my_perl, xs_init, 5, one_args, (char **)NULL);
    //
    //perl_run(my_perl);
    //perl_destruct(my_perl);
    //perl_free(my_perl);
    //PERL_SYS_TERM();

    return 0;
}
