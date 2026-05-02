#import "ZSignWrapper.h"

@implementation ZSignWrapper

+ (BOOL)signIPA:(NSString *)ipaPath
           p12:(NSString *)p12Path
      password:(NSString *)password
    provision:(NSString *)provisionPath
      bundleID:(NSString *)bundleID
    bundleName:(NSString *)bundleName
 bundleVersion:(NSString *)bundleVersion
       dylibs:(NSArray<NSString *> *)dylibs
 entitlements:(NSString *)entitlementsPath
        output:(NSString *)outputPath {
    
    NSLog(@"[ZSign] Signing not implemented for iOS yet");
    NSLog(@"[ZSign] Would sign: %@ with certificate: %@", ipaPath, p12Path);
    
    // For now, just copy the input to output to make the app functional
    NSError *error = nil;
    if ([[NSFileManager defaultManager] copyItemAtPath:ipaPath toPath:outputPath error:&error]) {
        return YES;
    }
    
    NSLog(@"[ZSign] Error: %@", error.localizedDescription);
    return NO;
}

@end
