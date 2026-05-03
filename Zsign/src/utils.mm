#import <Foundation/Foundation.h>
#include "signing.h"
#include "bundle.h"
#include "certcheck.h"
#include "openssl.h"

// MARK: - C Wrapper Functions
// These functions provide C-style access to the C++ classes

extern "C" {
    
    bool zsign_sign_app_wrapper(
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
    ) {
        try {
            ZSign::CSigning signing;
            
            // Load certificate if not ad-hoc
            if (!adhoc) {
                if (!certificate_path || strlen(certificate_path) == 0) {
                    NSLog(@"No certificate provided for non ad-hoc signing");
                    return false;
                }
                if (!signing.LoadCertificate(certificate_path, password ? password : "")) {
                    NSLog(@"Failed to load certificate");
                    return false;
                }
            }
            
            // Load provisioning profile if not ad-hoc
            if (!adhoc && provisioning_profile_path && strlen(provisioning_profile_path) > 0) {
                if (!signing.LoadProvisioningProfile(provisioning_profile_path)) {
                    NSLog(@"Failed to load provisioning profile");
                    return false;
                }
            }
            
            // Set bundle info if provided
            if (bundle_id && strlen(bundle_id) > 0) {
                signing.SetBundleId(bundle_id);
            }
            if (display_name && strlen(display_name) > 0) {
                signing.SetDisplayName(display_name);
            }
            if (version && strlen(version) > 0) {
                signing.SetVersion(version);
            }
            if (short_version && strlen(short_version) > 0) {
                signing.SetShortVersion(short_version);
            }
            
            // Sign the bundle
            const char* output = output_path && strlen(output_path) > 0 ? output_path : bundle_path;
            bool result = signing.Sign(bundle_path, output, adhoc);
            
            return result;
        } catch (...) {
            NSLog(@"Exception during signing");
            return false;
        }
    }
    
    bool zsign_check_certificate_wrapper(const char* certificate_path, const char* password) {
        try {
            ZSign::CCertCheck certCheck;
            return certCheck.LoadCertificate(certificate_path, password ? password : "");
        } catch (...) {
            return false;
        }
    }
    
    const char* zsign_get_certificate_info_wrapper(const char* certificate_path, const char* password) {
        try {
            ZSign::CCertCheck certCheck;
            if (!certCheck.LoadCertificate(certificate_path, password ? password : "")) {
                return nullptr;
            }
            
            // Get certificate info as JSON
            // This is a simplified version - you'd want to extract real info
            NSString* info = @"{ \"valid\": true }";
            return [info UTF8String];
        } catch (...) {
            return nullptr;
        }
    }
}
