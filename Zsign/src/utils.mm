#import <Foundation/Foundation.h>
#include "signing.h"
#include "bundle.h"
#include "certcheck.h"
#include "openssl.h"

// MARK: - C Wrapper Functions
// These functions will be called from Swift via the ZsignC target

extern "C" {
    
    bool zsign_sign_app(
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
            
            // Load certificate
            if (!signing.LoadCertificate(certificate_path, password)) {
                NSLog(@"Failed to load certificate");
                return false;
            }
            
            // Load provisioning profile if not ad-hoc
            if (!adhoc && provisioning_profile_path) {
                if (!signing.LoadProvisioningProfile(provisioning_profile_path)) {
                    NSLog(@"Failed to load provisioning profile");
                    return false;
                }
            }
            
            // Set bundle info if provided
            if (bundle_id) {
                signing.SetBundleId(bundle_id);
            }
            if (display_name) {
                signing.SetDisplayName(display_name);
            }
            if (version) {
                signing.SetVersion(version);
            }
            if (short_version) {
                signing.SetShortVersion(short_version);
            }
            
            // Sign the bundle
            bool result = signing.Sign(bundle_path, output_path ? output_path : bundle_path, adhoc);
            
            return result;
        } catch (...) {
            NSLog(@"Exception during signing");
            return false;
        }
    }
    
    bool zsign_check_certificate(const char* certificate_path, const char* password) {
        try {
            ZSign::CCertCheck certCheck;
            return certCheck.LoadCertificate(certificate_path, password);
        } catch (...) {
            return false;
        }
    }
    
    const char* zsign_get_certificate_info(const char* certificate_path, const char* password) {
        try {
            ZSign::CCertCheck certCheck;
            if (!certCheck.LoadCertificate(certificate_path, password)) {
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
