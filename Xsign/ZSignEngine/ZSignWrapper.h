#ifndef ZSignWrapper_h
#define ZSignWrapper_h

#include <Foundation/Foundation.h>

@interface ZSignWrapper : NSObject

+ (BOOL)signIPA:(NSString *)ipaPath
           p12:(NSString *)p12Path
      password:(NSString *)password
    provision:(NSString *)provisionPath
        output:(NSString *)outputPath;

@end

#endif
