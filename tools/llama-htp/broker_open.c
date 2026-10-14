/*
 * Ternux experimental llama.cpp Hexagon broker adapter.
 * Copyright (c) 2026 Sobuj Miah (@soobujmiah)
 * Licensed under the Apache License, Version 2.0.
 */
#define _GNU_SOURCE
#include <dlfcn.h>
#include <errno.h>
#include <fcntl.h>
#include <stdarg.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

static int broker_fd = -1;

static int open_with_broker(const char *path, int flags, mode_t mode,
                            const char *symbol) {
    if (broker_fd >= 0 &&
        (!strcmp(path, "/dev/fastrpc-cdsp") ||
         !strcmp(path, "/dev/fastrpc-cdsp-secure"))) {
        return fcntl(broker_fd, F_DUPFD_CLOEXEC, 0);
    }
    int (*real_open)(const char *, int, ...) = dlsym(RTLD_NEXT, symbol);
    if (!real_open) {
        errno = ENOSYS;
        return -1;
    }
    return real_open(path, flags, mode);
}

__attribute__((constructor)) static void load_broker_fd(void) {
    const char *value = getenv("TERNUX_HTP_BROKER_FD");
    if (!value || !*value) return;
    char *end = NULL;
    long fd = strtol(value, &end, 10);
    if (!end || *end || fd < 0 || fd > 0x7fffffffL) return;
    broker_fd = fcntl((int)fd, F_DUPFD_CLOEXEC, 0);
}

int open(const char *path, int flags, ...) {
    mode_t mode = 0;
    if ((flags & O_CREAT) || ((flags & O_TMPFILE) == O_TMPFILE)) {
        va_list ap;
        va_start(ap, flags);
        mode = (mode_t)va_arg(ap, unsigned int);
        va_end(ap);
    }
    return open_with_broker(path, flags, mode, "open");
}

int open64(const char *path, int flags, ...) {
    mode_t mode = 0;
    if ((flags & O_CREAT) || ((flags & O_TMPFILE) == O_TMPFILE)) {
        va_list ap;
        va_start(ap, flags);
        mode = (mode_t)va_arg(ap, unsigned int);
        va_end(ap);
    }
    return open_with_broker(path, flags, mode, "open64");
}
