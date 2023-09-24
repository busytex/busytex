#include <stdio.h>

FILE* orig_fopen(const char *path, const char *mode);
FILE* fopen(const char *path, const char *mode)
{
    fprintf(stderr, "log_file_access_preload: fopen(\"%s\", \"%s\")\n", path, mode);
    return orig_fopen(path, mode);
}
