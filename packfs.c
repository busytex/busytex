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

#include "packfs.h"
//size_t packfs_builtin_files_num, packfs_builtin_dirs_num; const char** packfs_builtin_abspaths; const char** packfs_builtin_abspaths_dirs; const char** packfs_builtin_starts; const char** packfs_builtin_ends;

enum {
    packfs_filefd_min = 1000000000, 
    packfs_filefd_max = 1000001000, 
    packfs_filepath_max_len = 256, 
    packfs_sep = '/'
};
int packfs_filefd[packfs_filefd_max - packfs_filefd_min];
FILE* packfs_fileptr[packfs_filefd_max - packfs_filefd_min];
size_t packfs_filesize[packfs_filefd_max - packfs_filefd_min];

int packfs_enabled = 
#ifdef PACKFS_DISABLE
0
#else
1
#endif
;

#define PACKFS_STRING_VALUE_(x) #x
#define PACKFS_STRING_VALUE(x) PACKFS_STRING_VALUE_(x)
char packfs_builtin_prefix[] = PACKFS_STRING_VALUE(PACKFS_BUILTIN_PREFIX);

extern int      __real_open(const char *path, int flags);                               
extern int      __real_close(int fd);                                                   
extern ssize_t  __real_read(int fd, void* buf, size_t count);                           
extern int      __real_access(const char *path, int flags);                             
extern off_t    __real_lseek(int fd, off_t offset, int whence);                         
extern int      __real_stat(const char *restrict path, struct stat *restrict statbuf);  
extern int      __real_fstat(int fd, struct stat * statbuf);                            
extern FILE*    __real_fopen(const char *path, const char *mode);                       
extern int      __real_fileno(FILE* stream);                                            

void packfs_sanitize_path(char* path_sanitized, const char* path)
{
    size_t len = path != NULL ? strlen(path) : 0;
    if(len == 0)
        path_sanitized[0] = '\0';

    // lstrips ./ in the beginning; collapses double consecutive slashes; and rstrips abc/asd/..
    for(int i = (path != NULL && len > 2 && path[0] == '.' && path[1] == packfs_sep) ? 2 : 0, k = 0; len > 0 && i < len; i++)
    {
        if(!(i > 1 && path[i] == packfs_sep && path[i - 1] == packfs_sep))
        {
            path_sanitized[k++] = path[i];
            path_sanitized[k] = '\0';
        }
    }
    
    size_t path_sanitized_len = strlen(path_sanitized);
    if(path_sanitized_len >= 3 && path_sanitized[path_sanitized_len - 1] == '.' && path_sanitized[path_sanitized_len - 2] == '.'  && path_sanitized[path_sanitized_len - 3] == packfs_sep)
    {
        path_sanitized[path_sanitized_len - 3] = '\0';
        char* last_slash = strrchr(path_sanitized, packfs_sep);
        if(last_slash != NULL)
            *last_slash = '\0';
    }
}

int packfs_path_in_range(const char* prefix, const char* path)
{
    if(prefix == NULL || prefix[0] == '\0' || path == NULL || path[0] == '\0')
        return 0;
    size_t prefix_len = strlen(prefix);
    size_t path_len = strlen(path);
    int prefix_endswith_slash = prefix[prefix_len - 1] == packfs_sep;
    int prefix_ok = 0 == strncmp(prefix, path, prefix_len - (prefix_endswith_slash ? 1 : 0));
    size_t prefix_len_m1 = prefix_endswith_slash ? (prefix_len - 1) : prefix_len;
    return prefix_ok && ((path_len == prefix_len_m1) || (path_len >= prefix_len && path[prefix_len_m1] == packfs_sep));
}

int packfs_open(const char* path, FILE** out)
{
    char path_sanitized[packfs_filepath_max_len]; packfs_sanitize_path(path_sanitized, path);

    FILE* fileptr = NULL;
    size_t filesize = 0;
    
    if(packfs_builtin_files_num > 0 && packfs_path_in_range(packfs_builtin_prefix, path_sanitized))
    {
        for(size_t i = 0; i < packfs_builtin_files_num; i++)
        {
            if(0 == strcmp(path_sanitized, packfs_builtin_abspaths[i]))
            {
                filesize = (size_t)(packfs_builtin_ends[i] - packfs_builtin_starts[i]);
                fileptr = fmemopen((void*)packfs_builtin_starts[i], filesize, "r");
                break;
            }
        }
    }

    if(out != NULL)
        *out = fileptr;

    for(size_t k = 0; fileptr != NULL && k < packfs_filefd_max - packfs_filefd_min; k++)
    {
        if(packfs_filefd[k] == 0)
        {
            packfs_filefd[k] = packfs_filefd_min + k;
            packfs_fileptr[k] = fileptr;
            packfs_filesize[k] = filesize;
            return packfs_filefd[k];
        }
    }

    return -1;
}

int packfs_close(int fd)
{
    if(fd < packfs_filefd_min || fd >= packfs_filefd_max)
        return -2;

    for(size_t k = 0; k < packfs_filefd_max - packfs_filefd_min; k++)
    {
        if(packfs_filefd[k] == fd)
        {
            packfs_filefd[k] = 0;
            packfs_filesize[k] = 0;
            int res = fclose(packfs_fileptr[k]);
            packfs_fileptr[k] = NULL;
            return res;
        }
    }
    return -2;
}

void* packfs_find(int fd, FILE* ptr)
{
    if(ptr != NULL)
    {
        for(size_t k = 0; k < packfs_filefd_max - packfs_filefd_min; k++)
        {
            if(packfs_fileptr[k] == ptr)
                return &packfs_filefd[k];
        }
        return NULL;
    }
    else
    {
        if(fd < packfs_filefd_min || fd >= packfs_filefd_max)
            return NULL;
        
        for(size_t k = 0; k < packfs_filefd_max - packfs_filefd_min; k++)
        {
            if(packfs_filefd[k] == fd)
                return packfs_fileptr[k];
        }
    }
    return NULL;
}

ssize_t packfs_read(int fd, void* buf, size_t count)
{
    FILE* ptr = packfs_find(fd, NULL);
    if(!ptr)
        return -1;
    return (ssize_t)fread(buf, 1, count, ptr);
}

int packfs_seek(int fd, long offset, int whence)
{
    FILE* ptr = packfs_find(fd, NULL);
    if(!ptr)
        return -1;
    return fseek(ptr, offset, whence);
}

int packfs_access(const char* path)
{
    char path_sanitized[packfs_filepath_max_len]; packfs_sanitize_path(path_sanitized, path);

    if(packfs_path_in_range(packfs_builtin_prefix, path_sanitized))
    {
        for(size_t i = 0; i < packfs_builtin_files_num; i++)
        {
            if(0 == strcmp(path_sanitized, packfs_builtin_abspaths[i]))
                return 0;
        }
        return -1;
    }
    
    return -2;
}

int packfs_stat(const char* path, int fd, struct stat *restrict statbuf)
{
    char path_sanitized[packfs_filepath_max_len]; packfs_sanitize_path(path_sanitized, path);
    
    if(packfs_path_in_range(packfs_builtin_prefix, path_sanitized))
    {
        for(size_t i = 0; i < packfs_builtin_files_num; i++)
        {
            if(0 == strcmp(path_sanitized, packfs_builtin_abspaths[i]))
            {
                *statbuf = (struct stat){0};
                statbuf->st_size = (off_t)(packfs_builtin_ends[i] - packfs_builtin_starts[i]);
                statbuf->st_mode = S_IFREG;
                return 0;
            }
        }
        for(size_t i = 0; i < packfs_builtin_dirs_num; i++)
        {
            if(0 == strcmp(path_sanitized, packfs_builtin_abspaths_dirs[i]))
            {
                *statbuf = (struct stat){0};
                statbuf->st_size = 0;
                statbuf->st_mode = S_IFDIR;
                return 0;
            }
        }
        return -1;
    }
    
    if(fd >= 0 && packfs_filefd_min <= fd && fd < packfs_filefd_max)
    {
        for(size_t k = 0; k < packfs_filefd_max - packfs_filefd_min; k++)
        {
            if(packfs_filefd[k] == fd)
            {
                *statbuf = (struct stat){0};
                statbuf->st_size = packfs_filesize[k];
                statbuf->st_mode = S_IFREG;
                return 0;
            }
        }
        return -1;
    }

    return -2;
}

///////////

FILE* __wrap_fopen(const char *path, const char *mode)
{
    if(packfs_enabled)
    {
        FILE* res = NULL;
        if(packfs_open(path, &res) >= 0)
            return res;
    }

    return __real_fopen(path, mode);
}

int __wrap_fileno(FILE *stream)
{
    int res = __real_fileno(stream);
    
    if(packfs_enabled && res < 0)
    {        
        int* ptr = packfs_find(-1, stream);
        res = ptr == NULL ? -1 : (*ptr);
    }
    
    return res;
}

int __wrap_open(const char *path, int flags, ...)
{
    if(packfs_enabled)
    {
        int res = packfs_open(path, NULL);
        if(res >= 0)
            return res;
    }
    
    return __real_open(path, flags);
}

int __wrap_close(int fd)
{
    if(packfs_enabled)
    {
        int res = packfs_close(fd);
        if(res >= -1)
            return res;
    }
    
    return __real_close(fd);
}


ssize_t __wrap_read(int fd, void* buf, size_t count)
{
    if(packfs_enabled)
    {
        ssize_t res = packfs_read(fd, buf, count);
        if(res >= 0)
            return res;
    }

    return __real_read(fd, buf, count);
}

off_t __wrap_lseek(int fd, off_t offset, int whence)
{
    if(packfs_enabled)
    {
        int res = packfs_seek(fd, (long)offset, whence);
        if(res >= 0)
            return res;
    }

    return __real_lseek(fd, offset, whence);
}

int __wrap_access(const char *path, int flags) 
{
    if(packfs_enabled)
    {
        int res = packfs_access(path);
        if(res >= -1)
            return res;
    }
    
    return __real_access(path, flags); 
}

int __wrap_stat(const char *restrict path, struct stat *restrict statbuf)
{
    if(packfs_enabled)
    {
        int res = packfs_stat(path, -1, statbuf);
        if(res >= -1)
            return res;
    }

    return __real_stat(path, statbuf);
}

int __wrap_fstat(int fd, struct stat * statbuf)
{
    if(packfs_enabled)
    {
        int res = packfs_stat(NULL, fd, statbuf);
        if(res >= -1)
            return res;
    }
    
    return __real_fstat(fd, statbuf);
}

// TODO: - a list of listing files, or a separate directory with listing files (to be enumerated), then archive file can be checked from the listing
// TODO: - a list of archive files, or a separate directory with archive files (to be enumerated), then a listing file can be checked if exists
// TODO: - lazy mode of initializing index and scanning the archive files / directory
