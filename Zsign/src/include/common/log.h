// log.h - Minimal logging class for Zsign
// This is a simplified version to allow compilation on iOS

#ifndef log_h
#define log_h

#include <stdio.h>
#include <stdarg.h>

class ZLog {
public:
    static void ErrorV(const char* format, ...) {
        va_list args;
        va_start(args, format);
        vfprintf(stderr, format, args);
        va_end(args);
    }
    
    static void WarningV(const char* format, ...) {
        va_list args;
        va_start(args, format);
        vfprintf(stderr, format, args);
        va_end(args);
    }
    
    static void InfoV(const char* format, ...) {
        va_list args;
        va_start(args, format);
        vfprintf(stdout, format, args);
        va_end(args);
    }
};

#endif /* log_h */
