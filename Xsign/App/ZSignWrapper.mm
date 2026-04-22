#import "ZSignWrapper.h"
#include "../External/zsign/src/common/common.h"
#include "../External/zsign/src/signing.h"
#include "../External/zsign/src/bundle.h"

/**
 * ZSignWrapper implementation.
 * This bridges the Swift SigningService to the C++ zsign engine.
 * It handles the full IPA signing flow: extraction, modification, and repackaging.
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

    ZSigner signer;

    // Configure signer with provided credentials
    signer.m_strP12Path = p12Path.UTF8String;
    signer.m_strPassword = password.UTF8String;
    signer.m_strProvisionPath = provisionPath.UTF8String;

    // Metadata Overrides
    if (bundleID && bundleID.length > 0) {
        signer.m_strBundleId = bundleID.UTF8String;
    }
    if (bundleName && bundleName.length > 0) {
        signer.m_strBundleName = bundleName.UTF8String;
    }
    if (bundleVersion && bundleVersion.length > 0) {
        signer.m_strBundleVersion = bundleVersion.UTF8String;
    }

    // Dylib Injection
    for (NSString *dylib in dylibs) {
        signer.m_arrDylibs.push_back(dylib.UTF8String);
    }

    // Standard ZSign options for robust signing
    signer.m_bForce = true; // Overwrite existing signatures

    NSLog(@"[ZSignWrapper] Executing signing for bundle %@...", bundleID ?: @"original");

    // Execute the core signing engine
    if (!signer.SignIPA(ipaPath.UTF8String, outputPath.UTF8String)) {
        NSLog(@"[ZSignWrapper] Internal engine failed to sign IPA.");
        return NO;
    }

    NSLog(@"[ZSignWrapper] IPA signed successfully at %@", outputPath);
    return YES;
}

@end
