#define _GNU_SOURCE
#include <stdio.h>
#include <string.h>

#include <unistd.h>
#include <errno.h>
#include <dlfcn.h>
#include <sys/stat.h>

// gcc -shared -fPIC log_file_access.c -o log_file_access.so -ldl
// override in fs: 'lstat', 'stat', 'access', 'fopen',

int execve(const char *filename, char *const argv[], char *const envp[])
{
    typedef int (*orig_func_type)(const char* filename, char * const argv[], char *const envp[]);
    fprintf(stderr, "log_file_access_preload: execve(\"%s\", {", filename); for(int i = 0; argv[i] != NULL; i++) {fprintf(stderr, "\"%s\", ", argv[i]);}  fprintf(stderr, "}, {...})\n");
    orig_func_type orig_func = (orig_func_type)dlsym(RTLD_NEXT, "execve");
    return orig_func(filename, argv, envp);
}
int execvp(const char *filename, char *const argv[])
{
    typedef int (*orig_func_type)(const char* filename, char * const argv[]);
    fprintf(stderr, "log_file_access_preload: execvp(\"%s\", {", filename); for(int i = 0; argv[i] != NULL; i++) {fprintf(stderr, "\"%s\", ", argv[i]);}  fprintf(stderr, "})\n");
    orig_func_type orig_func = (orig_func_type)dlsym(RTLD_NEXT, "execvp");
    return orig_func(filename, argv);
}

FILE* fopen(const char *path, const char *mode)
{
    typedef FILE* (*orig_func_type)(const char *path, const char *mode);
    fprintf(stderr, "log_file_access_preload: fopen(\"%s\", \"%s\")\n", path, mode);
    orig_func_type orig_func = (orig_func_type)dlsym(RTLD_NEXT, "fopen");
    return orig_func(path, mode);
}
int open(const char *path, int flags, mode_t mode)
{
    typedef int (*orig_func_type)(const char *pathname, int flags, mode_t mode);
    fprintf(stderr, "log_file_access_preload: open(\"%s\", %d)\n", path, flags);
    orig_func_type orig_func = (orig_func_type)dlsym(RTLD_NEXT, "open");
    return orig_func(path, flags, mode);
}
int open64(const char *path, int flags, mode_t mode)
{
    typedef int (*orig_func_type)(const char *pathname, int flags, mode_t mode);
    fprintf(stderr, "log_file_access_preload: open64(\"%s\", %d)\n", path, flags);
    orig_func_type orig_func = (orig_func_type)dlsym(RTLD_NEXT, "open64");
    return orig_func(path, flags, mode);
}
int openat(int dirfd, const char *path, int flags, mode_t mode)
{
    typedef int (*orig_func_type)(int dirfd, const char *pathname, int flags, mode_t mode);
    fprintf(stderr, "log_file_access_preload: openat(%d, \"%s\", %d)\n", dirfd, path, flags);
    orig_func_type orig_func = (orig_func_type)dlsym(RTLD_NEXT, "openat");
    return orig_func(dirfd, path, flags, mode);
}


int fileno(FILE *stream)
{
    typedef int (*orig_func_type)(FILE* stream);
    fprintf(stderr, "log_file_access_preload: fileno(%p)\n", (void*)stream);
    orig_func_type orig_func = (orig_func_type)dlsym(RTLD_NEXT, "fileno");
    return orig_func(stream);
}


int access(const char *path, int flags)
{
    typedef int (*orig_func_type)(const char *pathname, int flags);
    fprintf(stderr, "log_file_access_preload: access(\"%s\", %d)\n", path, flags);
    orig_func_type orig_func = (orig_func_type)dlsym(RTLD_NEXT, "access");
    return orig_func(path, flags);
}
int faccessat(int dirfd, const char *path, int mode, int flags)
{
    typedef int (*orig_func_type)(int dirfd, const char *pathname, int mode, int flags);
    fprintf(stderr, "log_file_access_preload: faccessat(%d, \"%s\", %d, %d)\n", dirfd, path, mode, flags);
    orig_func_type orig_func = (orig_func_type)dlsym(RTLD_NEXT, "faccessat");
    return orig_func(dirfd, path, mode, flags);
}


int stat(const char *restrict pathname, struct stat *restrict statbuf)
{
    typedef int (*orig_func_type)(const char *restrict pathname, struct stat *restrict statbuf);
    fprintf(stderr, "log_file_access_preload: stat(\"%s\", %p)\n", pathname, (void*)statbuf);
    orig_func_type orig_func = (orig_func_type)dlsym(RTLD_NEXT, "stat");
    return orig_func(pathname, statbuf);
}
int lstat(const char *restrict pathname, struct stat *restrict statbuf)
{
    typedef int (*orig_func_type)(const char *restrict pathname, struct stat *restrict statbuf);
    fprintf(stderr, "log_file_access_preload: lstat(\"%s\", %p)\n", pathname, (void*)statbuf);
    orig_func_type orig_func = (orig_func_type)dlsym(RTLD_NEXT, "lstat");
    return orig_func(pathname, statbuf);
}
int fstat(int fd, struct stat *restrict statbuf)
{
    typedef int (*orig_func_type)(int fd, struct stat *restrict statbuf);
    fprintf(stderr, "log_file_access_preload: fstat(%d, %p)\n", fd, (void*)statbuf);
    orig_func_type orig_func = (orig_func_type)dlsym(RTLD_NEXT, "fstat");
    return orig_func(fd, statbuf);
}
int fstatat(int dirfd, const char *restrict pathname, struct stat *restrict statbuf, int flags)
{
    typedef int (*orig_func_type)(int dirfd, const char *restrict pathname, struct stat *restrict statbuf, int flags);
    fprintf(stderr, "log_file_access_preload: fstat(%d, \"%s\", %p, %d)\n", dirfd, pathname, (void*)statbuf, flags);
    orig_func_type orig_func = (orig_func_type)dlsym(RTLD_NEXT, "fstatat");
    return orig_func(dirfd, pathname, statbuf, flags);
}
/*int fstatat64(int dirfd, const char *restrict pathname, struct stat64 *restrict statbuf, int flags)
{
    typedef int (*orig_func_type)(int dirfd, const char *restrict pathname, struct stat64 *restrict statbuf, int flags);
    fprintf(stderr, "log_file_access_preload: fstat64(%d, \"%s\", %p, %d)\n", dirfd, pathname, (void*)statbuf, flags);
    orig_func_type orig_func = (orig_func_type)dlsym(RTLD_NEXT, "fstatat64");
    return orig_func(dirfd, pathname, statbuf, flags);
}*/
int newfstatat(int dirfd, const char *restrict pathname, struct stat *restrict statbuf, int flags)
{
    typedef int (*orig_func_type)(int dirfd, const char *restrict pathname, struct stat *restrict statbuf, int flags);
    fprintf(stderr, "log_file_access_preload: newfstat(%d, \"%s\", %p, %d)\n", dirfd, pathname, (void*)statbuf, flags);
    orig_func_type orig_func = (orig_func_type)dlsym(RTLD_NEXT, "newfstatat");
    return orig_func(dirfd, pathname, statbuf, flags);
}


int unlink(const char * pathname)
{
    typedef int (*orig_func_type)(const char * pathname);
    fprintf(stderr, "log_file_access_preload: unlink(\"%s\")\n", pathname);
    orig_func_type orig_func = (orig_func_type)dlsym(RTLD_NEXT, "unlink");
    return orig_func(pathname);
}
int unlinkat(int dirfd, const char * pathname, int flags)
{
    typedef int (*orig_func_type)(int dirfd, const char * pathname, int flags);
    fprintf(stderr, "log_file_access_preload: unlinkat(%d, \"%s\", %d)\n", dirfd, pathname, flags);
    orig_func_type orig_func = (orig_func_type)dlsym(RTLD_NEXT, "unlinkat");
    return orig_func(dirfd, pathname, flags);
}


int link(const char * oldpath, const char * newpath)
{
    typedef int (*orig_func_type)(const char * oldpath, const char * newpath);
    fprintf(stderr, "log_file_access_preload: link(\"%s\", \"%s\")\n", oldpath, newpath);
    orig_func_type orig_func = (orig_func_type)dlsym(RTLD_NEXT, "link");
    return orig_func(oldpath, newpath);
}
int linkat(int olddirfd, const char *oldpath, int newdirfd, const char *newpath, int flags)
{
    typedef int (*orig_func_type)(int olddirfd, const char *oldpath, int newdirfd, const char *newpath, int flags);
    fprintf(stderr, "log_file_access_preload: linkat(%d, \"%s\", %d, \"%s\", %d)\n", olddirfd, oldpath, newdirfd, newpath, flags);
    orig_func_type orig_func = (orig_func_type)dlsym(RTLD_NEXT, "linkat");
    return orig_func(olddirfd, oldpath, newdirfd, newpath, flags);
}


int rename(const char * oldpath, const char * newpath)
{
    typedef int (*orig_func_type)(const char * oldpath, const char * newpath);
    fprintf(stderr, "log_file_access_preload: rename(\"%s\", \"%s\")\n", oldpath, newpath);
    orig_func_type orig_func = (orig_func_type)dlsym(RTLD_NEXT, "rename");
    return orig_func(oldpath, newpath);
}
int renameat(int olddirfd, const char *oldpath, int newdirfd, const char *newpath)
{
    typedef int (*orig_func_type)(int olddirfd, const char *oldpath, int newdirfd, const char *newpath);
    fprintf(stderr, "log_file_access_preload: renameat(%d, \"%s\", %d, \"%s\")\n", olddirfd, oldpath, newdirfd, newpath);
    orig_func_type orig_func = (orig_func_type)dlsym(RTLD_NEXT, "renameat");
    return orig_func(olddirfd, oldpath, newdirfd, newpath);
}
int renameat2(int olddirfd, const char *oldpath, int newdirfd, const char *newpath, unsigned int flags)
{
    typedef int (*orig_func_type)(int olddirfd, const char *oldpath, int newdirfd, const char *newpath, unsigned int flags);
    fprintf(stderr, "log_file_access_preload: renameat2(%d, \"%s\", %d, \"%s\", %u)\n", olddirfd, oldpath, newdirfd, newpath, flags);
    orig_func_type orig_func = (orig_func_type)dlsym(RTLD_NEXT, "renameat2");
    return orig_func(olddirfd, oldpath, newdirfd, newpath, flags);
}


int mkdir(const char *path, mode_t mode)
{
    typedef int (*orig_func_type)(const char *path, mode_t mode);
    fprintf(stderr, "log_file_access_preload: mkdir(\"%s\", %d)\n", path, (int)mode);
    orig_func_type orig_func = (orig_func_type)dlsym(RTLD_NEXT, "mkdir");
    return orig_func(path, mode);
}
int mkdirat(int dirfd, const char *path, mode_t mode)
{
    typedef int (*orig_func_type)(int dirrfd, const char *path, mode_t mode);
    fprintf(stderr, "log_file_access_preload: mkdirat(%d, \"%s\", %d)\n", dirfd, path, (int)mode);
    orig_func_type orig_func = (orig_func_type)dlsym(RTLD_NEXT, "mkdirat");
    return orig_func(dirfd, path, mode);
}


int rmdir(const char *path)
{
    typedef int (*orig_func_type)(const char *path);
    fprintf(stderr, "log_file_access_preload: rmdir(\"%s\")\n", path);
    orig_func_type orig_func = (orig_func_type)dlsym(RTLD_NEXT, "rmdir");
    return orig_func(path);
}
