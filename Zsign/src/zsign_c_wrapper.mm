// zsign_c_wrapper.mm - Objective-C++ wrapper for Zsign C++ library
// This file provides C functions that can be called from Swift via modulemap

#include "zsign.h"
#include "signing.h"
#include "certcheck.h"
#include "bundle.h"
#include "openssl.h"
#include <string>
#include <vector>
#include <set>

// C wrapper function for signing an app - matches Swift @_silgen_name("c_zsign_sign_app")
extern "C" bool c_zsign_sign_app(
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
    @autoreleasepool {
        // Convert C strings to C++ strings
        std::string strBundlePath(bundle_path ? bundle_path : "");
        std::string strCertPath(certificate_path ? certificate_path : "");
        std::string strPassword(password ? password : "");
        std::string strProvisioningProfile(provisioning_profile_path ? provisioning_profile_path : "");
        std::string strOutputPath(output_path ? output_path : "");
        std::string strBundleId(bundle_id ? bundle_id : "");
        std::string strDisplayName(display_name ? display_name : "");
        std::string strVersion(version ? version : "");
        std::string strShortVersion(short_version ? short_version : "");
        
        // For ad-hoc signing, we don't need certificate
        ZSignAsset zsa;
        if (!adhoc) {
            if (!zsa.Init(strCertPath,    // cert file (p12)
                          strCertPath,    // pkey file (p12)
                          strProvisioningProfile,
                          "",            // entitlements
                          strPassword,
                          false,          // not sha256 only
                          false,          // not single binary
                          true)) {        // is for signing folder
                return false;
            }
        }
        
        // Initialize ZBundle and sign the folder
        ZBundle bundle;
        
        // Apply ad-hoc setting
        // Note: ZBundle doesn't directly support adhoc, but ZSignAsset does
        
        std::vector<std::string> arrDylibFiles;
        std::vector<std::string> arrRemoveDylibNames;
        
        // Use bundle_id if provided, otherwise empty string to keep original
        std::string finalBundleId = strBundleId.empty() ? "" : strBundleId;
        std::string finalDisplayName = strDisplayName.empty() ? "" : strDisplayName;
        std::string finalVersion = strVersion.empty() ? "" : strVersion;
        
        bool result = bundle.SignFolder(&zsa,
                                        strBundlePath,
                                        finalBundleId,
                                        finalVersion,
                                        finalDisplayName,
                                        arrDylibFiles,
                                        arrRemoveDylibNames,
                                        false, // not force
                                        false, // not weak inject
                                        true,  // enable cache
                                        false  // not remove provision
        );
        
        return result;
    }
}

// C wrapper function for certificate check - matches Swift @_silgen_name("c_zsign_check_certificate")
extern "C" bool c_zsign_check_certificate(
    const char* certificate_path,
    const char* password
) {
    @autoreleasepool {
        std::string strCertPath(certificate_path ? certificate_path : "");
        std::string strPassword(password ? password : "");
        
        // Try to initialize ZSignAsset to check if cert is valid
        ZSignAsset zsa;
        bool result = zsa.Init(strCertPath,
                               strCertPath,
                               "",
                               "",
                               strPassword,
                               false,
                               false,
                               false);
        
        return result;
    }
}

// C wrapper function to get certificate info - matches Swift @_silgen_name("c_zsign_get_certificate_info")
extern "C" const char* c_zsign_get_certificate_info(
    const char* certificate_path,
    const char* password
) {
    @autoreleasepool {
        std::string strCertPath(certificate_path ? certificate_path : "");
        std::string strPassword(password ? password : "");
        
        // Initialize ZSignAsset to get cert info
        ZSignAsset zsa;
        if (!zsa.Init(strCertPath,
                       strCertPath,
                       "",
                       "",
                       strPassword,
                       false,
                       false,
                       false)) {
            return nullptr;
        }
        
        // Get certificate info as JSON
        // The ZSignAsset should have methods to get cert info
        // For now, return team ID as a simple implementation
        static std::string info;
        info = "{\"team_id\":\"" + zsa.m_strTeamId + "\",\"subject_cn\":\"" + zsa.m_strSubjectCN + "\"}";
        return info.c_str();
    }
}
