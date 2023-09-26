#define _GNU_SOURCE
#include <stdio.h>
#include <string.h>

#ifdef LOGFILEACCESSSTATIC

FILE* orig_fopen(const char *path, const char *mode);
FILE* fopen(const char *path, const char *mode)
{
    fprintf(stderr, "log_file_access: fopen(\"%s\", \"%s\")\n", path, mode);
    return orig_fopen(path, mode);
}

int orig_open(const char *path, int mode);
int open(const char *path, int mode)
{
    fprintf(stderr, "log_file_access: open(\"%s\", %d)\n", path, mode);
    return orig_open(path, mode);
}

#endif

#ifdef LOGFILEACCESSDYNAMIC
// gcc -shared -fPIC log_file_access.c -o log_file_access.so -ldl

#include <unistd.h>
#include <errno.h>
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
#endif
