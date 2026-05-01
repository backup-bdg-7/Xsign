#ifndef OPENSSL_SHA_H
#define OPENSSL_SHA_H

#include <CommonCrypto/CommonDigest.h>

#define SHA1(data, len, md) CC_SHA1(data, len, md)
#define SHA256(data, len, md) CC_SHA256(data, len, md)
#define SHA512(data, len, md) CC_SHA512(data, len, md)

typedef unsigned char uint8_t;

#endif /* OPENSSL_SHA_H */
