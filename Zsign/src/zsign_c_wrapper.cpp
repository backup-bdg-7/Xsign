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
