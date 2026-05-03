// zsign_c_wrapper.cpp - Pure C wrapper for Zsign C++ classes
// This file provides C-linkage functions that can be called from Objective-C/Swift

#include <string>
#include "signing.h"
#include "bundle.h"
#include "certcheck.h"
#include "openssl.h"

extern "C" {
    
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
    ) {
        try {
            ZSign::CSigning signing;
            
            // Load certificate if not ad-hoc
            if (!adhoc) {
                if (!certificate_path || strlen(certificate_path) == 0) {
                    return false;
                }
                std::string certPath(certificate_path);
                std::string pwd(password ? password : "");
                if (!signing.LoadCertificate(certPath, pwd)) {
                    return false;
                }
            }
            
            // Load provisioning profile if not ad-hoc
            if (!adhoc && provisioning_profile_path && strlen(provisioning_profile_path) > 0) {
                std::string provPath(provisioning_profile_path);
                if (!signing.LoadProvisioningProfile(provPath)) {
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
            std::string inputPath(bundle_path);
            std::string output = (output_path && strlen(output_path) > 0) ? std::string(output_path) : inputPath;
            bool result = signing.Sign(inputPath, output, adhoc);
            
            return result;
        } catch (...) {
            return false;
        }
    }
    
    bool c_zsign_check_certificate(
        const char* certificate_path,
        const char* password
    ) {
        try {
            ZSign::CCertCheck certCheck;
            std::string certPath(certificate_path);
            std::string pwd(password ? password : "");
            return certCheck.LoadCertificate(certPath, pwd);
        } catch (...) {
            return false;
        }
    }
    
    const char* c_zsign_get_certificate_info(
        const char* certificate_path,
        const char* password
    ) {
        try {
            ZSign::CCertCheck certCheck;
            std::string certPath(certificate_path);
            std::string pwd(password ? password : "");
            if (!certCheck.LoadCertificate(certPath, pwd)) {
                return nullptr;
            }
            
            // Return a simple JSON string
            // In real implementation, you'd extract actual certificate info
            static const char* info = "{\"valid\": true}";
            return info;
        } catch (...) {
            return nullptr;
        }
    }
}
