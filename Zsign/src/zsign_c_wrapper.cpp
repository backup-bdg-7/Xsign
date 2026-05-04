#include "zsign_c.h"
#include "openssl.h"
#include "bundle.h"
#include "signing.h"
#include "certcheck.h"
#include "macho.h"
#include "metadata.h"
#include <string>
#include <vector>
#include <cstring>
#include <sstream>

using namespace std;

static ZSignAsset g_zsa;
static vector<string> g_arrDylibFiles;
static vector<string> g_arrRemoveDylibNames;

static vector<string> splitDylibPaths(const string& str) {
    vector<string> result;
    stringstream ss(str);
    string item;
    while (getline(ss, item, ',')) {
        if (!item.empty()) result.push_back(item);
    }
    return result;
}

extern "C" bool c_zsign_sign_app_simple(
    const char* bundle_path,
    const char* certificate_path,
    const char* password,
    const char* provisioning_profile_path
) {
    string strCertFile(certificate_path ? certificate_path : "");
    string strPKeyFile("");
    string strProvFile(provisioning_profile_path ? provisioning_profile_path : "");
    string strEntitleFile("");
    string strPassword(password ? password : "");
    bool bForce = true;
    bool bWeakInject = false;
    bool bEnableCache = true;
    bool bRemoveProvision = false;

    try {
        if (!g_zsa.Init(strCertFile, strPKeyFile, strProvFile, strEntitleFile, strPassword, false, false, false)) {
            return false;
        }

        ZBundle bundle;
        string strBundlePath(bundle_path ? bundle_path : "");

        return bundle.SignFolder(&g_zsa, strBundlePath, "", "", "", 
                                g_arrDylibFiles, g_arrRemoveDylibNames, bForce, bWeakInject, bEnableCache, bRemoveProvision);

    } catch (...) {
        return false;
    }
}

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
    try {
        string strCertPath(certificate_path ? certificate_path : "");
        string strPassword(password ? password : "");
        string strProvPath(provisioning_profile_path ? provisioning_profile_path : "");
        
        ZSignAsset zsa;
        if (!zsa.Init(strCertPath, strCertPath, strProvPath, "", strPassword, false, false, true)) {
            return false;
        }
        
        ZBundle bundle;
        string strBundlePath(bundle_path ? bundle_path : "");
        bool bForce = false;
        bool bWeakInject = false;
        bool bEnableCache = false;
        bool bRemoveProvision = false;
        
        return bundle.SignFolder(&zsa, strBundlePath, 
                               output_path ? output_path : "",
                               bundle_id ? bundle_id : "",
                               display_name ? display_name : "",
                               g_arrDylibFiles, g_arrRemoveDylibNames, 
                               bForce, bWeakInject, bEnableCache, bRemoveProvision);
    } catch (...) {
        return false;
    }
}



extern "C" const char* c_zsign_get_dylibs(const char* file_path) {
    static string result = "[]";
    try {
        string strPath(file_path ? file_path : "");
        ZMachO macho;
        if (!macho.Init(strPath.c_str())) {
            return result.c_str();
        }
        
        // Get dylibs - use ZMachO to get loaded dylibs
        vector<string> arrDylibs;
        // This would need to use the proper ZMachO API
        // For now, return empty array
        result = "[]";
        return result.c_str();
    } catch (...) {
        return result.c_str();
    }
}


extern "C" bool c_zsign_check_certificate(const char* certificate_path, const char* password) {
    string strPath(certificate_path ? certificate_path : "");
    string strPassword(password ? password : "");
    try {
        // Use CheckCertificate from certcheck.h
        return CheckCertificate(strPath, strPassword) == 0;
    } catch (...) { return false; }
}

extern "C" const char* c_zsign_get_certificate_info(const char* certificate_path, const char* password) {
    static string strInfo;
    string strPath(certificate_path ? certificate_path : "");
    string strPassword(password ? password : "");
    try {
        ZSignAsset zsa;
        if (!zsa.Init(strPath, strPath, "", "", strPassword, false, false, false)) {
            strInfo = "{}";
            return strInfo.c_str();
        }
        
        // Build JSON-like info string
        strInfo = "{\"team_id\":\"" + zsa.m_strTeamId + "\",\"subject_cn\":\"" + zsa.m_strSubjectCN + "\"}";
        return strInfo.c_str();
    } catch (...) {
        strInfo = "{}";
        return strInfo.c_str();
    }
}

extern "C" bool c_zsign_set_entitlements(const char* entitlements_json) {
    // This would need to parse entitlements and set them in g_zsa
    return true;
}

extern "C" void c_zsign_set_option(const char* option_name, bool enabled) {
    string strOption(option_name ? option_name : "");
    try {
        if (strOption == "sha256_only") g_zsa.m_bSHA256Only = enabled;
        else if (strOption == "ad_hoc") g_zsa.m_bAdhoc = enabled;
    } catch (...) {}
}


extern "C" const char* c_zsign_get_metadata(const char* app_folder, const char* output_dir, const char* ipa_file) {
    static string result = "{}";
    try {
        string strAppFolder(app_folder ? app_folder : "");
        string strOutputDir(output_dir ? output_dir : "");
        string strIpaFile(ipa_file ? ipa_file : "");
        
        if (GetMetadata(strAppFolder, strOutputDir, strIpaFile)) {
            // Return some metadata info
            result = "{\"status\":\"success\"}";
        } else {
            result = "{\"status\":\"failed\"}";
        }
        return result.c_str();
    } catch (...) {
        result = "{\"status\":\"error\"}";
        return result.c_str();
    }
}
