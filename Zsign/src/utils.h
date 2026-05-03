// utils.h - Bridging header for Zsign C++ to Swift
#import <Foundation/Foundation.h>

#ifdef __cplusplus
extern "C" {
#endif
    
    bool zsign_sign_app(
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
    );
    
    bool zsign_check_certificate(const char* certificate_path, const char* password);
    
    const char* zsign_get_certificate_info(const char* certificate_path, const char* password);
    
#ifdef __cplusplus
}
#endif
