#define _GNU_SOURCE
#include <string.h>
#include <stdio.h>
#include <unistd.h>
#include <errno.h>
#include <stdarg.h>
#include <fcntl.h>
#include <stdlib.h>

#include <sys/stat.h>
#include <sys/mman.h>
#include <sys/types.h>

#include "perlpack.h"

enum {
    packfs_filefd_min = 1000000000, 
    packfs_filefd_max = 1000001000, 
    packfs_filepath_max_len = 128, 
};
struct packfs_context
{
    int initialized, disabled;
    
    int (*orig_open)(const char *path, int flags);
    int (*orig_close)(int fd);
    ssize_t (*orig_read)(int fd, void* buf, size_t count);
    int (*orig_access)(const char *path, int flags);
    off_t (*orig_lseek)(int fd, off_t offset, int whence);
    int (*orig_stat)(const char *restrict path, struct stat *restrict statbuf);
    int (*orig_fstat)(int fd, struct stat * statbuf);
    FILE* (*orig_fopen)(const char *path, const char *mode);
    int (*orig_fileno)(FILE* stream);
    
    int packfs_filefd[packfs_filefd_max - packfs_filefd_min];
    FILE* packfs_fileptr[packfs_filefd_max - packfs_filefd_min];
    size_t packfs_filesize[packfs_filefd_max - packfs_filefd_min];
    
    size_t packfs_builtin_files_num;
    char packfs_builtin_prefix[packfs_filepath_max_len];
    const char** packfs_builtin_starts;
    const char** packfs_builtin_ends;
    const char** packfs_builtin_safepaths;
    const char** packfs_builtin_abspaths;
};

struct packfs_context* packfs_ensure_context()
{
    static struct packfs_context packfs_ctx = {0};

    if(packfs_ctx.initialized != 1)
    {
        extern int orig_open(const char *path, int flags); packfs_ctx.orig_open = orig_open;
        extern int orig_close(int fd); packfs_ctx.orig_close = orig_close;
        extern ssize_t orig_read(int fd, void* buf, size_t count); packfs_ctx.orig_read = orig_read;
        extern int orig_access(const char *path, int flags); packfs_ctx.orig_access = orig_access;
        extern off_t orig_lseek(int fd, off_t offset, int whence); packfs_ctx.orig_lseek = orig_lseek;
        extern int orig_stat(const char *restrict path, struct stat *restrict statbuf); packfs_ctx.orig_stat = orig_stat;
        extern int orig_fstat(int fd, struct stat * statbuf); packfs_ctx.orig_fstat = orig_fstat;
        extern FILE* orig_fopen(const char *path, const char *mode); packfs_ctx.orig_fopen = orig_fopen;
        extern int orig_fileno(FILE* stream); packfs_ctx.orig_fileno = orig_fileno;
        // TODO: append / if missing
#define PACKFS_STRING_VALUE_(x) #x
#define PACKFS_STRING_VALUE(x) PACKFS_STRING_VALUE_(x)
        strcpy(packfs_ctx.packfs_builtin_prefix,
#ifdef PACKFS_BUILTIN_PREFIX
            PACKFS_STRING_VALUE(PACKFS_BUILTIN_PREFIX)
#else
        ""
#endif
        );
#undef PACKFS_STRING_VALUE_
#undef PACKFS_STRING_VALUE

        packfs_ctx.packfs_builtin_files_num = 0;
        packfs_ctx.packfs_builtin_starts = NULL;
        packfs_ctx.packfs_builtin_ends = NULL;
        packfs_ctx.packfs_builtin_safepaths = NULL;
        packfs_ctx.packfs_builtin_abspaths = NULL;
        
        packfs_ctx.initialized = 1;
        packfs_ctx.disabled = 1;

#ifdef PACKFS_BUILTIN_PREFIX
        packfs_ctx.disabled = 0;
        packfs_ctx.packfs_builtin_files_num = packfs_builtin_files_num;
        packfs_ctx.packfs_builtin_starts = packfs_builtin_starts;
        packfs_ctx.packfs_builtin_ends = packfs_builtin_ends;
        packfs_ctx.packfs_builtin_safepaths = packfs_builtin_safepaths;
        packfs_ctx.packfs_builtin_abspaths = packfs_builtin_abspaths;
#endif
    }
    
    return &packfs_ctx;
}

void packfs_sanitize_path(char* path_sanitized, const char* path)
{
    size_t len = path != NULL ? strlen(path) : 0;
    if(len == 0)
        path_sanitized[0] = '\0';

    for(int i = (path != NULL && len > 2 && path[0] == '.' && path[1] == '/') ? 2 : 0, k = 0; len > 0 && i < len; i++)
    {
        if(!(i > 1 && path[i] == '/' && path[i - 1] == '/'))
        {
            path_sanitized[k++] = path[i];
            path_sanitized[k] = '\0';
        }
    }
}

int packfs_strncmp(const char* prefix, const char* path, size_t count)
{
    return (prefix != NULL && prefix[0] != '\0' && path != NULL && path[0] != '\0') ? strncmp(prefix, path, count) : 1;
}

int packfs_open(struct packfs_context* packfs_ctx, const char* path, FILE** out)
{
    char path_sanitized[packfs_filepath_max_len]; packfs_sanitize_path(path_sanitized, path);

    FILE* fileptr = NULL;
    size_t filesize = 0;
    
    if(packfs_ctx->packfs_builtin_files_num > 0 && 0 == packfs_strncmp(packfs_ctx->packfs_builtin_prefix, path_sanitized, strlen(packfs_ctx->packfs_builtin_prefix)))
    {
        for(size_t i = 0; i < packfs_ctx->packfs_builtin_files_num; i++)
        {
            if(0 == strcmp(path_sanitized, packfs_ctx->packfs_builtin_abspaths[i]))
            {
                filesize = (size_t)(packfs_ctx->packfs_builtin_ends[i] - packfs_ctx->packfs_builtin_starts[i]);
                fileptr = fmemopen((void*)packfs_ctx->packfs_builtin_starts[i], filesize, "r");
                break;
            }
        }
    }

    if(out != NULL)
        *out = fileptr;

    for(size_t k = 0; fileptr != NULL && k < packfs_filefd_max - packfs_filefd_min; k++)
    {
        if(packfs_ctx->packfs_filefd[k] == 0)
        {
            packfs_ctx->packfs_filefd[k] = packfs_filefd_min + k;
            packfs_ctx->packfs_fileptr[k] = fileptr;
            packfs_ctx->packfs_filesize[k] = filesize;
            return packfs_ctx->packfs_filefd[k];
        }
    }

    return -1;
}

int packfs_close(struct packfs_context* packfs_ctx, int fd)
{
    if(fd < packfs_filefd_min || fd >= packfs_filefd_max)
        return -2;

    for(size_t k = 0; k < packfs_filefd_max - packfs_filefd_min; k++)
    {
        if(packfs_ctx->packfs_filefd[k] == fd)
        {
            packfs_ctx->packfs_filefd[k] = 0;
            packfs_ctx->packfs_filesize[k] = 0;
            int res = fclose(packfs_ctx->packfs_fileptr[k]);
            packfs_ctx->packfs_fileptr[k] = NULL;
            return res;
        }
    }
    return -2;
}

void* packfs_find(struct packfs_context* packfs_ctx, int fd, FILE* ptr)
{
    if(ptr != NULL)
    {
        for(size_t k = 0; k < packfs_filefd_max - packfs_filefd_min; k++)
        {
            if(packfs_ctx->packfs_fileptr[k] == ptr)
                return &packfs_ctx->packfs_filefd[k];
        }
        return NULL;
    }
    else
    {
        if(fd < packfs_filefd_min || fd >= packfs_filefd_max)
            return NULL;
        
        for(size_t k = 0; k < packfs_filefd_max - packfs_filefd_min; k++)
        {
            if(packfs_ctx->packfs_filefd[k] == fd)
                return packfs_ctx->packfs_fileptr[k];
        }
    }
    return NULL;
}

ssize_t packfs_read(struct packfs_context* packfs_ctx, int fd, void* buf, size_t count)
{
    FILE* ptr = packfs_find(packfs_ctx, fd, NULL);
    if(!ptr)
        return -1;
    return (ssize_t)fread(buf, 1, count, ptr);
}

int packfs_seek(struct packfs_context* packfs_ctx, int fd, long offset, int whence)
{
    FILE* ptr = packfs_find(packfs_ctx, fd, NULL);
    if(!ptr)
        return -1;
    return fseek(ptr, offset, whence);
}

int packfs_access(struct packfs_context* packfs_ctx, const char* path)
{
    char path_sanitized[packfs_filepath_max_len]; packfs_sanitize_path(path_sanitized, path);

    if(0 == packfs_strncmp(packfs_ctx->packfs_builtin_prefix, path_sanitized, strlen(packfs_ctx->packfs_builtin_prefix)))
    {
        for(size_t i = 0; i < packfs_ctx->packfs_builtin_files_num; i++)
        {
            if(0 == strcmp(path_sanitized, packfs_ctx->packfs_builtin_abspaths[i]))
                return 0;
        }
        return -1;
    }
    
    return -2;
}

int packfs_stat(struct packfs_context* packfs_ctx, const char* path, int fd, struct stat *restrict statbuf)
{
    char path_sanitized[packfs_filepath_max_len]; packfs_sanitize_path(path_sanitized, path);
    
    if(0 == packfs_strncmp(packfs_ctx->packfs_builtin_prefix, path_sanitized, strlen(packfs_ctx->packfs_builtin_prefix)))
    {
        for(size_t i = 0; i < packfs_ctx->packfs_builtin_files_num; i++)
        {
            if(0 == strcmp(path_sanitized, packfs_ctx->packfs_builtin_abspaths[i]))
            {
                *statbuf = (struct stat){0};
                //if(packfs_builtin[i].isdir)
                //{
                //    statbuf->st_size = 0;
                //    statbuf->st_mode = S_IFDIR;
                //}
                //else
                {
                    statbuf->st_size = (off_t)(packfs_ctx->packfs_builtin_ends[i] - packfs_ctx->packfs_builtin_starts[i]);
                    statbuf->st_mode = S_IFREG;
                }
                return 0;
            }
        }
        return -1;
    }
    
    if(fd >= 0 && packfs_filefd_min <= fd && fd < packfs_filefd_max)
    {
        for(size_t k = 0; k < packfs_filefd_max - packfs_filefd_min; k++)
        {
            if(packfs_ctx->packfs_filefd[k] == fd)
            {
                *statbuf = (struct stat){0};
                statbuf->st_size = packfs_ctx->packfs_filesize[k];
                statbuf->st_mode = S_IFREG;
                return 0;
            }
        }
        return -1;
    }

    return -2;
}

///////////

FILE* fopen(const char *path, const char *mode)
{
    struct packfs_context* packfs_ctx = packfs_ensure_context();
    if(!packfs_ctx->disabled)
    {
        FILE* res = NULL;
        if(packfs_open(packfs_ctx, path, &res) >= 0)
        {
            return res;
        }
    }

    FILE* res = packfs_ctx->orig_fopen(path, mode);
    return res;
}

int fileno(FILE *stream)
{
    struct packfs_context* packfs_ctx = packfs_ensure_context();
    
    int res = packfs_ctx->orig_fileno(stream);
    
    if(!packfs_ctx->disabled && res < 0)
    {        
        int* ptr = packfs_find(packfs_ctx, -1, stream);
        res = ptr == NULL ? -1 : (*ptr);
    }
    
    return res;
}

int open(const char *path, int flags, ...)
{
    struct packfs_context* packfs_ctx = packfs_ensure_context();
    if(!packfs_ctx->disabled)
    {
        int res = packfs_open(packfs_ctx, path, NULL);
        if(res >= 0)
        { 
            return res;
        }
    }
    
    int res = packfs_ctx->orig_open(path, flags);
    return res;
}

int close(int fd)
{
    struct packfs_context* packfs_ctx = packfs_ensure_context();
    if(!packfs_ctx->disabled)
    {
        int res = packfs_close(packfs_ctx, fd);
        if(res >= -1)
        {
            return res;
        }
    }
    
    int res = packfs_ctx->orig_close(fd);
    return res;
}


ssize_t read(int fd, void* buf, size_t count)
{
    struct packfs_context* packfs_ctx = packfs_ensure_context();
    if(!packfs_ctx->disabled)
    {
        ssize_t res = packfs_read(packfs_ctx, fd, buf, count);
        if(res >= 0)
        {
            return res;
        }
    }

    ssize_t res = packfs_ctx->orig_read(fd, buf, count);
    return res;
}

off_t lseek(int fd, off_t offset, int whence)
{
    struct packfs_context* packfs_ctx = packfs_ensure_context();
    if(!packfs_ctx->disabled)
    {
        int res = packfs_seek(packfs_ctx, fd, (long)offset, whence);
        if(res >= 0)
        {
            return res;
        }
    }

    off_t res = packfs_ctx->orig_lseek(fd, offset, whence);
    return res;
}


int access(const char *path, int flags) 
{
    struct packfs_context* packfs_ctx = packfs_ensure_context();
    if(!packfs_ctx->disabled)
    {
        int res = packfs_access(packfs_ctx, path);
        if(res >= -1)
        {
            return res;
        }
    }
    
    int res = packfs_ctx->orig_access(path, flags); 
    return res;
}

int stat(const char *restrict path, struct stat *restrict statbuf)
{
    struct packfs_context* packfs_ctx = packfs_ensure_context();
    if(!packfs_ctx->disabled)
    {
        int res = packfs_stat(packfs_ctx, path, -1, statbuf);
        if(res >= -1)
        {
            return res;
        }
    }

    int res = packfs_ctx->orig_stat(path, statbuf);
    return res;
}

int fstat(int fd, struct stat * statbuf)
{
    struct packfs_context* packfs_ctx = packfs_ensure_context();
    if(!packfs_ctx->disabled)
    {
        int res = packfs_stat(packfs_ctx, NULL, fd, statbuf);
        if(res >= -1)
        {
            return res;
        }
    }
    
    int res = packfs_ctx->orig_fstat(fd, statbuf);
    return res;
}

//struct packfs_context* packfs_ctx = packfs_ensure_context();
