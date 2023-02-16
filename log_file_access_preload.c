// gcc -shared -fPIC log_file_access_preload.c -o log_file_access_preload.so -ldl

#define _GNU_SOURCE
#include <stdio.h>
#include <unistd.h>
#include <errno.h>
#include <string.h>
#include <dlfcn.h>

FILE* fopen(const char *path, const char *mode)
{
    fprintf(stderr, "log_file_access_preload: fopen(\"%s\", \"%s\")\n", path, mode);

    typedef FILE* (*orig_fopen_func_type)(const char *path, const char *mode);
    orig_fopen_func_type orig_func = (orig_fopen_func_type)dlsym(RTLD_NEXT, "fopen");
    return orig_func(path, mode);
}

int open(const char *path, int flags)
{
    fprintf(stderr, "log_file_access_preload: open(\"%s\", %d)\n", path, flags);

    typedef int (*orig_open_func_type)(const char *pathname, int flags);
    orig_open_func_type orig_func = (orig_open_func_type)dlsym(RTLD_NEXT, "open");
    return orig_func(path, flags);
}
