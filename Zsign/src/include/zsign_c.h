// zsign_c.h - C interface for Zsign functionality
// This header will be processed by Swift Package Manager

#ifndef zsign_c_h
#define zsign_c_h

#include <stdbool.h>
#include <stddef.h>

#ifdef __cplusplus
extern "C" {
#endif

// Sign an iOS app bundle - matches Swift @_silgen_name("c_zsign_sign_app")
// Returns true on success
bool c_zsign_sign_app(
    const char* bundle_path,
    const char* certificate_path,
    const char* password,
    const char* provisioning_profile_path,
    const char* output_path,
    const char* bundle_id,
    const char* display_name,
    const char* version,
    const char* short_version,
    bool adhoc
);

// Simple version for signing (for backward compatibility)
// Returns true on success
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
    const char* password"
);

// Get certificate information as JSON string
// Returns a static string (do not free), or NULL on failure
const char* c_zsign_get_certificate_info(
    const char* certificate_path,
    const char* password"
);

// Get dylibs from a Mach-O file as JSON string
// Returns a static string (do not free), or NULL on failure
const char* c_zsign_get_dylibs(const char* file_path);

// Set entitlements (JSON string)
bool c_zsign_set_entitlements(const char* entitlements_json);

// Set signing options
void c_zsign_set_option(const char* option_name, bool enabled);

#ifdef __cplusplus
}
#endif

#endif /* zsign_c_h */
