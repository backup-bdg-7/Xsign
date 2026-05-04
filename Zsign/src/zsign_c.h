// zsign_c.h - C interface for Zsign functionality
// This header will be processed by Swift Package Manager

#ifndef zsign_c_h
#define zsign_c_h

#include <stdbool.h>
#include <stddef.h>

#ifdef __cplusplus
extern "C" {
#endif

// Sign an iOS app bundle
// Returns true on success
// Simplified version with fewer parameters for Swift compatibility
bool c_zsign_sign_app_simple(
    const char* bundle_path,
    const char* certificate_path,
    const char* password,
    const char* provisioning_profile_path
);

// Check if a certificate is valid
// Returns true if valid
bool c_zsign_check_certificate(
    const char* certificate_path,
    const char* password
);

// Get certificate information as JSON string
// Returns a static string (do not free), or NULL on failure
const char* c_zsign_get_certificate_info(
    const char* certificate_path,
    const char* password
);

#ifdef __cplusplus
}
#endif

#endif /* zsign_c_h */
