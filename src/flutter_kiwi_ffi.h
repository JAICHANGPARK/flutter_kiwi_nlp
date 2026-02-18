#include <stdint.h>

#if _WIN32
#define FFI_PLUGIN_EXPORT __declspec(dllexport)
#else
#define FFI_PLUGIN_EXPORT
#endif

#ifdef __cplusplus
extern "C" {
#endif

typedef struct flutter_kiwi_ffi_handle flutter_kiwi_ffi_handle_t;

// Initializes an analyzer instance.
// model_path can be null/empty for embedded/default model paths.
FFI_PLUGIN_EXPORT flutter_kiwi_ffi_handle_t* flutter_kiwi_ffi_init(
    const char* model_path,
    int32_t num_threads,
    int32_t build_options,
    int32_t match_options);

// Releases all resources for an analyzer instance.
FFI_PLUGIN_EXPORT int32_t flutter_kiwi_ffi_close(flutter_kiwi_ffi_handle_t* handle);

// Returns analysis output as a JSON string allocated by this library.
// Call flutter_kiwi_ffi_free_string to free the returned value.
FFI_PLUGIN_EXPORT char* flutter_kiwi_ffi_analyze_json(
    flutter_kiwi_ffi_handle_t* handle,
    const char* text,
    int32_t top_n,
    int32_t match_options);

// Runs analysis for multiple sentences and returns a JSON object:
// {"results":[{"candidates":[...]}, ...]}.
// Call flutter_kiwi_ffi_free_string to free the returned value.
FFI_PLUGIN_EXPORT char* flutter_kiwi_ffi_analyze_json_batch(
    flutter_kiwi_ffi_handle_t* handle,
    const char* const* texts,
    int32_t text_count,
    int32_t top_n,
    int32_t match_options);

// Runs analysis and returns the token count of the first candidate.
// Returns 0 on success and writes to out_token_count.
FFI_PLUGIN_EXPORT int32_t flutter_kiwi_ffi_analyze_token_count(
    flutter_kiwi_ffi_handle_t* handle,
    const char* text,
    int32_t top_n,
    int32_t match_options,
    int32_t* out_token_count);

// Runs analysis for multiple sentences and returns first-candidate token
// counts for each sentence in order.
// Returns 0 on success and writes to out_token_counts[text_count].
FFI_PLUGIN_EXPORT int32_t flutter_kiwi_ffi_analyze_token_count_batch(
    flutter_kiwi_ffi_handle_t* handle,
    const char* const* texts,
    int32_t text_count,
    int32_t top_n,
    int32_t match_options,
    int32_t* out_token_counts);

// Runs repeated analysis for the same batch and returns the summed
// first-candidate token counts across all runs.
// Returns 0 on success and writes to out_total_tokens.
FFI_PLUGIN_EXPORT int32_t flutter_kiwi_ffi_analyze_token_count_batch_runs(
    flutter_kiwi_ffi_handle_t* handle,
    const char* const* texts,
    int32_t text_count,
    int32_t runs,
    int32_t top_n,
    int32_t match_options,
    int64_t* out_total_tokens);

// Adds a user word to the in-memory dictionary.
FFI_PLUGIN_EXPORT int32_t flutter_kiwi_ffi_add_user_word(
    flutter_kiwi_ffi_handle_t* handle,
    const char* word,
    const char* tag,
    float score);

// Frees heap strings returned by this library.
FFI_PLUGIN_EXPORT void flutter_kiwi_ffi_free_string(char* value);

// Returns last error for current thread. Returns null if there is no error.
FFI_PLUGIN_EXPORT const char* flutter_kiwi_ffi_last_error(void);

// Returns wrapper version.
FFI_PLUGIN_EXPORT const char* flutter_kiwi_ffi_version(void);

#ifdef __cplusplus
}
#endif
