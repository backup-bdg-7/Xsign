#ifndef ZSignWrapper_h
#define ZSignWrapper_h

#import <Foundation/Foundation.h>

@interface ZSignWrapper : NSObject

/**
 * Performs full IPA signing using the zsign engine.
 * @param ipaPath Path to the input IPA file.
 * @param p12Path Path to the .p12 certificate file.
 * @param password Password for the .p12 file.
 * @param provisionPath Path to the .mobileprovision file.
 * @param entitlementsPath Optional path to a custom entitlements plist.
 * @param outputPath Path where the signed IPA should be saved.
 * @return YES if signing succeeded, NO otherwise.
 */
+ (BOOL)signIPA:(NSString *)ipaPath
           p12:(NSString *)p12Path
      password:(NSString *)password
    provision:(NSString *)provisionPath
 entitlements:(NSString *)entitlementsPath
        output:(NSString *)outputPath;

@end

#endif
