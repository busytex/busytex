/*
 * A fake implementation of the deprecated `getpass()` function for
 * Cosmopolitan Libc and Emscripten.
 * It is included directly in `texlive/texk/dvipdfm-x/dvipdfmx.c`.
 */
#if defined(__COSMOPOLITAN__) || defined(__EMSCRIPTEN__)
#include <stdio.h>
#include <stdlib.h>
static char* getpass(const char* prompt) {
  fprintf(stderr, "Password encryption is not supported\n");
  exit(1);
}
#endif
