#define _GNU_SOURCE
#include <stdio.h>
#include <string.h>

#define concat2(X, Y) X ## Y
#define concat(X, Y) concat2(X, Y)
#define busymain(x) concat(busymain_, x)

//#define busymain(x) (busymain_##x)

#define APPLET(name1, name2) { if(strcmp(#name1, argv[1]) == 0 || strcmp(#name2, argv[1]) == 0)   { argv[1] = argv[0]; optind = 1; return busymain(name1)(argc - 1, argv + 1); } }

#ifdef __cplusplus
#define extern  extern "C"
#endif

extern int optind;

extern int busymain_splitup(int argc, char* argv[]);
extern int busymain_fixwrites(int argc, char* argv[]);
extern int busymain_makecpool(int argc, char* argv[]);

int main(int argc, char* argv[]);
{
    if(argc < 2)
        return 0;

    APPLET(splitup, splitup)
    APPLET(fixwrites, fixwrites)
    APPLET(makecpool, makecpool)
    return 1;
}

