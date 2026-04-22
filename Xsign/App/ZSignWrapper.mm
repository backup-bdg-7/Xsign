#import "ZSignWrapper.h"
#include "../External/zsign/src/common/common.h"
#include "../External/zsign/src/signing.h"
#include "../External/zsign/src/bundle.h"

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
    signer.m_strP12Path = p12Path.UTF8String;
    signer.m_strPassword = password.UTF8String;
    signer.m_strProvisionPath = provisionPath.UTF8String;

    if (bundleID && bundleID.length > 0) signer.m_strBundleId = bundleID.UTF8String;
    if (bundleName && bundleName.length > 0) signer.m_strBundleName = bundleName.UTF8String;
    if (bundleVersion && bundleVersion.length > 0) signer.m_strBundleVersion = bundleVersion.UTF8String;

    for (NSString *dylib in dylibs) {
        signer.m_arrDylibs.push_back(dylib.UTF8String);
    }

    signer.m_bForce = true;

    return signer.SignIPA(ipaPath.UTF8String, outputPath.UTF8String);
}

@end
