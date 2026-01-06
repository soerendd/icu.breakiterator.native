#ifndef ICU_BREAKITERATOR_WRAPPER_H
#define ICU_BREAKITERATOR_WRAPPER_H

#include <unicode/ubrk.h>
#include <unicode/ustring.h>
#include <unicode/uversion.h>

#ifdef __cplusplus
extern "C" {
#endif

#ifdef _WIN32
    #ifdef ICU_BREAKITERATOR_EXPORTS
        #define ICU_BREAKITERATOR_API __declspec(dllexport)
    #else
        #define ICU_BREAKITERATOR_API __declspec(dllimport)
    #endif
#else
    #define ICU_BREAKITERATOR_API __attribute__((visibility("default")))
#endif

typedef struct BreakIteratorHandle BreakIteratorHandle;

ICU_BREAKITERATOR_API BreakIteratorHandle* icu_breakiterator_create_line(const char* locale, UErrorCode* status);

ICU_BREAKITERATOR_API void icu_breakiterator_set_text(BreakIteratorHandle* handle, const char* text, int32_t textLength, UErrorCode* status);

ICU_BREAKITERATOR_API int32_t icu_breakiterator_next(BreakIteratorHandle* handle);

ICU_BREAKITERATOR_API int32_t icu_breakiterator_previous(BreakIteratorHandle* handle);

ICU_BREAKITERATOR_API int32_t icu_breakiterator_first(BreakIteratorHandle* handle);

ICU_BREAKITERATOR_API void icu_breakiterator_destroy(BreakIteratorHandle* handle);

ICU_BREAKITERATOR_API void icu_get_version(UVersionInfo versionArray);

#ifdef __cplusplus
}
#endif

#endif
