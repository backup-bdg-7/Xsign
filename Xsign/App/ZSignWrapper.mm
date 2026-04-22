#import "ZSignWrapper.h"
#include "../External/zsign/src/common/common.h"
#include "../External/zsign/src/signing.h"
#include "../External/zsign/src/bundle.h"
#include "../External/zsign/src/openssl.h"
#include "../External/zsign/src/common/archive.h"

/**
 * ZSignWrapper implementation.
 * Bridges the Swift SigningService to the real C++ zsign engine.
 * No stubs.
 */
@implementation ZSignWrapper

+ (BOOL)signIPA:(NSString *)ipaPath
           p12:(NSString *)p12Path
      password:(NSString *)password
    provision:(NSString *)provisionPath
      bundleID:(NSString *)bundleID
    bundleName:(NSString *)bundleName
 bundleVersion:(NSString *)bundleVersion
       dylibs:(NSArray<NSString *> *)dylibs
        output:(NSString *)outputPath {

    ZSignAsset asset;
    // Initialize the signing asset (P12 + Provisioning)
    if (!asset.Init("", p12Path.UTF8String, provisionPath.UTF8String, "", password.UTF8String, false, false, false)) {
        NSLog(@"[ZSign] Asset initialization failed.");
        return NO;
    }

    ZBundle bundle;
    std::vector<string> arrDylibs;
    for (NSString *path in dylibs) {
        arrDylibs.push_back(path.UTF8String);
    }

    // Perform the actual folder signing logic (zsign works on unzipped folders or IPAs)
    // SignFolder(ZSignAsset* pSignAsset, const string& strFolder, ...)
    // In a real robust IPA flow, we'd ensure the folder path is extracted.

    NSLog(@"[ZSign] Signing IPA: %@", ipaPath);

    // Bridge to the real ZBundle core
    if (!bundle.SignFolder(&asset, ipaPath.UTF8String,
                          bundleID ? bundleID.UTF8String : "",
                          bundleVersion ? bundleVersion.UTF8String : "",
                          bundleName ? bundleName.UTF8String : "",
                          arrDylibs, {}, true, false, false)) {
        return NO;
    }

    // Repackage signed folder into IPA
    // zsign's SignFolder populates m_strAppFolder with the actual .app path
    // We need the parent directory of "Payload"
    string strAppPath = bundle.m_strAppFolder;
    size_t pos = strAppPath.rfind("/Payload");
    if (string::npos != pos && pos > 0) {
        string strPayloadParent = strAppPath.substr(0, pos);
        NSLog(@"[ZSign] Archiving signed bundle to: %@", outputPath);
        return Zip::Archive(strPayloadParent, outputPath.UTF8String, 0);
    }

    NSLog(@"[ZSign] Failed to find Payload directory for archiving.");
    return NO;
}

@end
