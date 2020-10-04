#include <string.h>

extern int optind;

extern int busymain_xetex(int argc, char* argv[]);
extern int busymain_xdvipdfmx(int argc, char* argv[]);
extern int busymain_bibtex8(int argc, char* argv[]);

int main(int argc, char* argv[])
{
    if(argc < 2)
        return 0;

    if(strcmp("xetex", argv[1]) == 0 || strcmp("xelatex", argv[1]) == 0)
    {
        argv[1] = argv[0];
        optind = 1;
        return busymain_xetex(argc - 1, argv + 1);
    }
    else if(strcmp("xdvipdfmx", argv[1]) == 0)
    {
        argv[1] = argv[0];
        optind = 1;
        return busymain_xdvipdfmx(argc - 1, argv + 1);
    }
    else if(strcmp("bibtex8", argv[1]) == 0)
    {
        argv[1] = argv[0];
        optind = 1;
        return busymain_bibtex8(argc - 1, argv + 1);
    }
}
