#include "zsign_c.h"
#include "signing.h"
#include "certcheck.h"
#include "bundle.h"
#include "archo.h"
#include <string>
#include <vector>
#include <cstring>
#include <sstream>

using namespace std;
using namespace ZSign;

static ZSign g_signing;

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
        g_signing = ZSign();
        if (!adhoc && !strCertificatePath.empty()) {
            if (!g_signing.SetCertificate(strCertificatePath, strPassword)) return false;
        }
        if (!strProvisioningPath.empty()) {
            if (!g_signing.SetProvisioningProfile(strProvisioningPath)) return false;
        }
        if (!strOutputPath.empty()) g_signing.SetOutputPath(strOutputPath);
        if (!strBundleID.empty()) g_signing.SetBundleID(strBundleID);
        if (!strDisplayName.empty()) g_signing.SetDisplayName(strDisplayName);
        if (!strVersion.empty()) g_signing.SetVersion(strVersion);
        if (!strShortVersion.empty()) g_signing.SetShortVersion(strShortVersion);
        if (!strDylibPaths.empty()) {
            vector<string> dylibs = splitDylibPaths(strDylibPaths);
            for (auto& dylib : dylibs) g_signing.AddDylibPath(dylib);
        }
        if (adhoc) g_signing.SetAdHoc(true);
        return g_signing.SignBundle(strBundlePath);
    } catch (...) {
        return false;
    }
}

extern "C" bool c_zsign_check_certificate(const char* certificate_path, const char* password) {
    string strCertificatePath(certificate_path ? certificate_path : "");
    string strPassword(password ? password : "");
    try {
        return CheckCertificate(strCertificatePath, strPassword) == 0;
    } catch (...) { return false; }
}

extern "C" const char* c_zsign_get_certificate_info(const char* certificate_path, const char* password) {
    static string strInfo;
    string strCertificatePath(certificate_path ? certificate_path : "");
    string strPassword(password ? password : "");
    try {
        strInfo = GetCertificateInfoJSON(strCertificatePath, strPassword);
        return strInfo.c_str();
    } catch (...) {
        strInfo = "{}";
        return strInfo.c_str();
    }
}

extern "C" bool c_zsign_set_entitlements(const char* entitlements_json) {
    string strEntitlements(entitlements_json ? entitlements_json : "");
    try {
        g_signing.SetEntitlements(strEntitlements);
        return true;
    } catch (...) { return false; }
}

extern "C" void c_zsign_set_option(const char* option_name, bool enabled) {
    string strOption(option_name ? option_name : "");
    try {
        if (strOption == "weak_inject") g_signing.SetWeakInject(enabled);
        else if (strOption == "sha256_only") g_signing.SetSHA256Only(enabled);
        else if (strOption == "remove_extensions") g_signing.SetRemoveExtensions(enabled);
        else if (strOption == "remove_watch_app") g_signing.SetRemoveWatchApp(enabled);
        else if (strOption == "enable_documents") g_signing.SetEnableDocuments(enabled);
    } catch (...) {}
}
