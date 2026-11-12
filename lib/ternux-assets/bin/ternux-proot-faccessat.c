/*
 * Alpine PRoot compatibility shim for GLib's GFile existence checks.
 * On Android PRoot, faccessat(AT_EACCESS | AT_SYMLINK_NOFOLLOW) can fail
 * with EINVAL even for normal guest files. Retry only that unsupported-flags
 * case with flags cleared. Ternux runs the desktop as one unprivileged user.
 */
extern int *__errno_location(void);

int faccessat(int dirfd, const char *path, int mode, int flags) {
  register long x0 __asm__("x0") = dirfd;
  register long x1 __asm__("x1") = (long)path;
  register long x2 __asm__("x2") = mode;
  register long x3 __asm__("x3") = flags;
  register long x8 __asm__("x8") = 48; /* AArch64 __NR_faccessat */
  __asm__ volatile("svc 0" : "+r"(x0) : "r"(x1), "r"(x2), "r"(x3), "r"(x8) : "memory", "cc");

  if (x0 == -22 && flags != 0) { /* EINVAL: retry without unsupported flags */
    x0 = dirfd;
    x1 = (long)path;
    x2 = mode;
    x3 = 0;
    x8 = 48;
    __asm__ volatile("svc 0" : "+r"(x0) : "r"(x1), "r"(x2), "r"(x3), "r"(x8) : "memory", "cc");
  }

  if (x0 < 0) {
    *__errno_location() = (int)-x0;
    return -1;
  }
  return 0;
}
