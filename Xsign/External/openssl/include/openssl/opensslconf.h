/* opensslconf.h */
/* This is a minimal opensslconf.h for iOS build */

#ifndef OPENSSL_OPENSSLCONF_H
#define OPENSSL_OPENSSLCONF_H

#ifdef __cplusplus
extern "C" {
#endif

/* Define if we have threads */
#define OPENSSL_THREADS

/* Define if we use _POSIX_C_SOURCE */
/* #undef OPENSSL_USE_POSIX_C_SOURCE */

/* Define if we use _XOPEN_SOURCE */
/* #undef OPENSSL_USE_XOPEN_SOURCE */

/* Define if we use _XOPEN_SOURCE_EXTENDED */
/* #undef OPENSSL_USE_XOPEN_SOURCE_EXTENDED */

/* Define if we want to use _REENTRANT */
/* #undef OPENSSL_USE_REENTRANT */

/* Define if we want to use __THREAD */
/* #undef OPENSSL_USE___THREAD */

/* Define if we want to debug memory */
/* #undef OPENSSL_DEBUG_MEMORY */

/* Define if we want to use _BSD_SOURCE */
/* #undef OPENSSL_USE_BSD_SOURCE */

/* Define if we want to use _GNU_SOURCE */
/* #undef OPENSSL_USE_GNU_SOURCE */

/* Define if we want to use _DEFAULT_SOURCE */
/* #undef OPENSSL_USE_DEFAULT_SOURCE */

#ifdef __cplusplus
}
#endif

#endif /* OPENSSL_OPENSSLCONF_H */
