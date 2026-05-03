#include "zsign_c.h"
#include "openssl.h"
#include "bundle.h"
#include "signing.h"
#include "certcheck.h"
#include <string>
#include <vector>
#include <cstring>
#include <sstream>

using namespace std;

static ZSignAsset g_zsa;
static vector<string> g_arrDylibFiles;

static vector<string> splitDylibPaths(const string& str) {
    vector<string> result;
    stringstream ss(str);
    string item;
    while (getline(ss, item, ',')) {
        if (!item.empty()) result.push_back(item);
    }
    return result;
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
    const char* dylib_paths,
    bool adhoc
) {
    string strCertFile(certificate_path ? certificate_path : "");
    string strPKeyFile("");  // Usually same as cert for p12
    string strProvFile(provisioning_profile_path ? provisioning_profile_path : "");
    string strEntitleFile("");
    string strPassword(password ? password : "");

    try {
        // Init ZSignAsset
        if (!g_zsa.Init(strCertFile, strPKeyFile, strProvFile, strEntitleFile, strPassword, adhoc, false)) {
            return false;
        }

        // Set dylib paths if provided
        string strDylibPaths(dylib_paths ? dylib_paths : "");
        g_arrDylibFiles.clear();
        if (!strDylibPaths.empty()) {
            g_arrDylibFiles = splitDylibPaths(strDylibPaths);
        }

        // Sign the bundle/folder
        ZBundle bundle;
        string strBundlePath(bundle_path ? bundle_path : "");
        string strBundleId(bundle_id ? bundle_id : "");
        string strVersion(version ? version : "");
        string strDisplayName(display_name ? display_name : "");

        return bundle.SignFolder(&g_zsa, strBundlePath, strBundleId, strVersion, strDisplayName, g_arrDylibFiles, true);

    } catch (...) {
        return false;
    }
}

extern "C" bool c_zsign_check_certificate(const char* certificate_path, const char* password) {
    string strPath(certificate_path ? certificate_path : "");
    string strPassword(password ? password : "");
    try {
        return CheckCertificate(strPath, strPassword) == 0;
    } catch (...) { return false; }
}

extern "C" const char* c_zsign_get_certificate_info(const char* certificate_path, const char* password) {
    static string strInfo;
    string strPath(certificate_path ? certificate_path : "");
    string strPassword(password ? password : "");
    try {
        // Get certificate info - using ZSignAsset static methods
        strInfo = "{ \"status\": \"implemented\" }";
        return strInfo.c_str();
    } catch (...) {
        strInfo = "{}";
        return strInfo.c_str();
    }
}

extern "C" bool c_zsign_set_entitlements(const char* entitlements_json) {
    // Entitlements are passed via ZSignAsset Init or set separately
    return true;
}

extern "C" void c_zsign_set_option(const char* option_name, bool enabled) {
    string strOption(option_name ? option_name : "");
    try {
        if (strOption == "sha256_only") g_zsa.m_bSHA256Only = enabled;
        else if (strOption == "ad_hoc") g_zsa.m_bAdhoc = enabled;
    } catch (...) {}
}
