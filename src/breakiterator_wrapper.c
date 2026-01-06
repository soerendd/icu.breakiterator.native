#include "icu_breakiterator_wrapper.h"
#include <stdlib.h>
#include <string.h>

struct BreakIteratorHandle {
    UBreakIterator* iterator;
    UChar* text;
    int32_t textLength;
};

ICU_BREAKITERATOR_API BreakIteratorHandle* icu_breakiterator_create_line(const char* locale, UErrorCode* status) {
    if (status == NULL) {
        return NULL;
    }
    
    *status = U_ZERO_ERROR;
    BreakIteratorHandle* handle = (BreakIteratorHandle*)malloc(sizeof(BreakIteratorHandle));
    if (handle == NULL) {
        *status = U_MEMORY_ALLOCATION_ERROR;
        return NULL;
    }
    
    handle->iterator = ubrk_open(UBRK_LINE, locale, NULL, 0, status);
    handle->text = NULL;
    handle->textLength = 0;
    
    if (U_FAILURE(*status)) {
        free(handle);
        return NULL;
    }
    
    return handle;
}

ICU_BREAKITERATOR_API void icu_breakiterator_set_text(BreakIteratorHandle* handle, const char* text, int32_t textLength, UErrorCode* status) {
    if (handle == NULL || text == NULL || status == NULL) {
        if (status != NULL) *status = U_ILLEGAL_ARGUMENT_ERROR;
        return;
    }
    
    *status = U_ZERO_ERROR;
    
    if (handle->text != NULL) {
        free(handle->text);
    }
    
    int32_t requiredLength = 0;
    u_strFromUTF8(NULL, 0, &requiredLength, text, textLength, status);
    if (*status != U_BUFFER_OVERFLOW_ERROR && U_FAILURE(*status)) {
        handle->text = NULL;
        handle->textLength = 0;
        return;
    }
    
    *status = U_ZERO_ERROR;
    handle->text = (UChar*)malloc((requiredLength + 1) * sizeof(UChar));
    if (handle->text == NULL) {
        *status = U_MEMORY_ALLOCATION_ERROR;
        handle->textLength = 0;
        return;
    }
    
    u_strFromUTF8(handle->text, requiredLength + 1, &handle->textLength, text, textLength, status);
    if (U_FAILURE(*status)) {
        free(handle->text);
        handle->text = NULL;
        handle->textLength = 0;
        return;
    }
    
    ubrk_setText(handle->iterator, handle->text, handle->textLength, status);
}

ICU_BREAKITERATOR_API int32_t icu_breakiterator_next(BreakIteratorHandle* handle) {
    if (handle == NULL || handle->iterator == NULL) {
        return UBRK_DONE;
    }
    
    return ubrk_next(handle->iterator);
}

ICU_BREAKITERATOR_API int32_t icu_breakiterator_previous(BreakIteratorHandle* handle) {
    if (handle == NULL || handle->iterator == NULL) {
        return UBRK_DONE;
    }
    
    return ubrk_previous(handle->iterator);
}

ICU_BREAKITERATOR_API int32_t icu_breakiterator_first(BreakIteratorHandle* handle) {
    if (handle == NULL || handle->iterator == NULL) {
        return UBRK_DONE;
    }
    return ubrk_first(handle->iterator);
}

ICU_BREAKITERATOR_API void icu_breakiterator_destroy(BreakIteratorHandle* handle) {
    if (handle != NULL) {
        if (handle->iterator != NULL) {
            ubrk_close(handle->iterator);
        }
        if (handle->text != NULL) {
            free(handle->text);
        }
        free(handle);
    }
}

ICU_BREAKITERATOR_API void icu_get_version(UVersionInfo versionArray) {
    u_getVersion(versionArray);
}
