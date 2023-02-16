#define _GNU_SOURCE
#include <stdio.h>
#include <unistd.h>
#include <errno.h>
#include <string.h>
#include <dlfcn.h>

typedef FILE* (*orig_fopen_func_type)(const char *path, const char *mode);
typedef int (*orig_open_func_type)(const char *pathname, int flags);

FILE* fopen(const char *path, const char *mode)
{
    fprintf(stderr, "log_file_access_preload: fopen(\"%s\", \"%s\")\n", path, mode);

    orig_fopen_func_type orig_func;
    orig_func = (orig_fopen_func_type)dlsym(RTLD_NEXT, "fopen");
    return orig_func(path, mode);
}

int open(const char *pathname, int flags)
{
    fprintf(stderr, "log_file_access_preload: open(\"%s\", %d)\n", pathname, flags);

    orig_open_func_type orig_func;
    orig_func = (orig_open_func_type)dlsym(RTLD_NEXT, "open");
    return orig_func(pathname, flags);
}
