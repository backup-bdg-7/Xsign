// log.h - Logging class for Zsign

#ifndef log_h
#define log_h

#include <stdio.h>
#include <stdarg.h>

class ZLog {
public:
    static const int E_NONE = 0;
    static const int E_ERROR = 1;
    static const int E_INFO = 2;
    static const int E_DEBUG = 3;
    static const int E_WARN = 4;
    
    static int g_nLogLevel;
    
    static void _Print(const char* szLog, int nColor = 0);
    static void Print(int nLevel, const char* szLog);
    static void PrintV(int nLevel, const char* szFormat, ...);
    
    static bool Error(const char* szLog);
    static bool ErrorV(const char* szFormat, ...);
    
    static bool Success(const char* szLog);
    static bool SuccessV(const char* szFormat, ...);
    
    static bool PrintResult(bool bSuccess, const char* szLog);
    static bool PrintResultV(bool bSuccess, const char* szFormat, ...);
    
    static bool Warn(const char* szLog);
    static bool WarnV(const char* szFormat, ...);
    
    static void Print(const char* szLog);
    static void PrintV(const char* szFormat, ...);
    
    static void Debug(const char* szLog);
    static void DebugV(const char* szFormat, ...);
};

#endif /* log_h */
