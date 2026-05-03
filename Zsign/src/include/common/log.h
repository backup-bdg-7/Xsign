// log.h - Minimal logging class for Zsign
// This is a simplified version to allow compilation on iOS

#ifndef log_h
#define log_h

#include <stdio.h>
#include <stdarg.h>

class ZLog {
public:
    static void ErrorV(const char* format, va_list args) {
        vfprintf(stderr, format, args);
    }
    
    static void WarningV(const char* format, va_list args) {
        vfprintf(stderr, format, args);
    }
    
    static void InfoV(const char* format, va_list args) {
        vfprintf(stdout, format, args);
    }
};

#endif /* log_h */
