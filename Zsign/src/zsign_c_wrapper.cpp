// zsign_c_wrapper.cpp - C++ implementation of C interface for Zsign
// This file implements the functions declared in zsign_c.h

#include "zsign_c.h"
#include "signing.h"
#include "certcheck.h"
#include "bundle.h"
#include "archo.h"
#include "utils.h"
#include <string>
#include <vector>
#include <cstring>
#include <sstream>

using namespace std;

// Global signing instance
static CSigning g_signing;

// Helper to split comma-separated string
static vector<string> splitDylibPaths(const string& str) {
    vector<string> result;
    stringstream ss(str);
    string item;
    while (getline(ss, item, ',')) {
        if (!item.empty()) {
            result.push_back(item);
        }
    }
    return result;
}

// Sign an iOS app bundle
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
    const char* dylib_paths,
    bool adhoc
) {
    // Convert C strings to C++ strings
    string strBundlePath(bundle_path ? bundle_path : "");
    string strCertificatePath(certificate_path ? certificate_path : "");
    string strPassword(password ? password : "");
    string strProvisioningPath(provisioning_profile_path ? provisioning_profile_path : "");
    string strOutputPath(output_path ? output_path : "");
    string strBundleID(bundle_id ? bundle_id : "");
    string strDisplayName(display_name ? display_name : "");
    string strVersion(version ? version : "");
    string strShortVersion(short_version ? short_version : "");
    string strDylibPaths(dylib_paths ? dylib_paths : "");
    
    try {
        // Reset signing instance
        g_signing = CSigning();
        
        // Set certificate and password
        if (!adhoc && !strCertificatePath.empty()) {
            if (!g_signing.SetCertificate(strCertificatePath, strPassword)) {
                return false;
            }
        }
        
        // Set provisioning profile
        if (!strProvisioningPath.empty()) {
            if (!g_signing.SetProvisioningProfile(strProvisioningPath)) {
                return false;
            }
        }
        
        // Set output path
        if (!strOutputPath.empty()) {
            g_signing.SetOutputPath(strOutputPath);
        }
        
        // Set bundle properties if provided
        if (!strBundleID.empty()) {
            g_signing.SetBundleID(strBundleID);
        }
        if (!strDisplayName.empty()) {
            g_signing.SetDisplayName(strDisplayName);
        }
        if (!strVersion.empty()) {
            g_signing.SetVersion(strVersion);
        }
        if (!strShortVersion.empty()) {
            g_signing.SetShortVersion(strShortVersion);
        }
        
        // Set dylib paths for injection
        if (!strDylibPaths.empty()) {
            vector<string> dylibs = splitDylibPaths(strDylibPaths);
            for (const auto& dylib : dylibs) {
                g_signing.AddDylibPath(dylib);
            }
        }
        
        // Perform ad-hoc signing if requested
        if (adhoc) {
            g_signing.SetAdHoc(true);
        }
        
        // Sign the bundle
        return g_signing.SignBundle(strBundlePath);
        
    } catch (...) {
        return false;
    }
}

// Check if a certificate is valid
bool c_zsign_check_certificate(
    const char* certificate_path,
    const char* password
) {
    string strCertificatePath(certificate_path ? certificate_path : "");
    string strPassword(password ? password : "");
    
    try {
        CCertCheck certCheck;
        return certCheck.CheckCertificate(strCertificatePath, strPassword);
    } catch (...) {
        return false;
    }
}

// Get certificate information as JSON string
const char* c_zsign_get_certificate_info(
    const char* certificate_path,
    const char* password
) {
    static string strInfo;
    string strCertificatePath(certificate_path ? certificate_path : "");
    string strPassword(password ? password : "");
    
    try {
        CCertCheck certCheck;
        strInfo = certCheck.GetCertificateInfoJSON(strCertificatePath, strPassword);
        return strInfo.c_str();
    } catch (...) {
        strInfo = "{}";
        return strInfo.c_str();
    }
}

// Set entitlements for signing
bool c_zsign_set_entitlements(
    const char* entitlements_json
) {
    string strEntitlements(entitlements_json ? entitlements_json : "");
    
    try {
        g_signing.SetEntitlements(strEntitlements);
        return true;
    } catch (...) {
        return false;
    }
}

// Enable/disable specific signing options
void c_zsign_set_option(
    const char* option_name,
    bool enabled
) {
    string strOption(option_name ? option_name : "");
    
    try {
        if (strOption == "weak_inject") {
            g_signing.SetWeakInject(enabled);
        } else if (strOption == "sha256_only") {
            g_signing.SetSHA256Only(enabled);
        } else if (strOption == "remove_extensions") {
            g_signing.SetRemoveExtensions(enabled);
        } else if (strOption == "remove_watch_app") {
            g_signing.SetRemoveWatchApp(enabled);
        } else if (strOption == "enable_documents") {
            g_signing.SetEnableDocuments(enabled);
        }
    } catch (...) {
        // Ignore
    }
}
