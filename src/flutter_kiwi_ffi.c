#include "flutter_kiwi_ffi.h"

#include <stdarg.h>
#include <stddef.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#if _WIN32
#include <windows.h>
#define KIWI_TLS __declspec(thread)
#define kiwi_dlopen(path) LoadLibraryA(path)
#define kiwi_dlsym(handle, name) GetProcAddress((HMODULE)handle, name)
#define kiwi_dlclose(handle) FreeLibrary((HMODULE)handle)
#else
#include <dlfcn.h>
#define KIWI_TLS __thread
#define kiwi_dlopen(path) dlopen(path, RTLD_NOW | RTLD_LOCAL)
#define kiwi_dlsym(handle, name) dlsym(handle, name)
#define kiwi_dlclose(handle) dlclose(handle)
#endif

#define KIWI_BUILD_DEFAULT (15 | 0x0400)
#define KIWI_MATCH_ALL_WITH_NORMALIZING ((1 | 2 | 4 | 8 | 16 | (1 << 23)) | (1 << 16))
#define KIWI_DIALECT_STANDARD 0
#define KIWI_DIALECT_ALL ((1 << 10) - 1)

typedef void* kiwi_h;
typedef void* kiwi_builder_h;
typedef void* kiwi_res_h;
typedef void* kiwi_morphset_h;
typedef void* kiwi_pretokenized_h;
typedef struct kiwi_typo* kiwi_typo_h;

typedef struct {
  int match_options;
  kiwi_morphset_h blocklist;
  int open_ending;
  int allowed_dialects;
  float dialect_cost;
} kiwi_analyze_option_t;

typedef const char* (*fn_kiwi_version)(void);
typedef const char* (*fn_kiwi_error)(void);
typedef void (*fn_kiwi_clear_error)(void);
typedef kiwi_builder_h (*fn_kiwi_builder_init)(const char*, int, int, int);
typedef int (*fn_kiwi_builder_close)(kiwi_builder_h);
typedef int (*fn_kiwi_builder_add_word)(kiwi_builder_h, const char*, const char*, float);
typedef kiwi_h (*fn_kiwi_builder_build)(kiwi_builder_h, kiwi_typo_h, float);
typedef int (*fn_kiwi_close)(kiwi_h);
typedef kiwi_res_h (*fn_kiwi_analyze)(kiwi_h, const char*, int, kiwi_analyze_option_t, kiwi_pretokenized_h);
typedef int (*fn_kiwi_res_size)(kiwi_res_h);
typedef float (*fn_kiwi_res_prob)(kiwi_res_h, int);
typedef int (*fn_kiwi_res_word_num)(kiwi_res_h, int);
typedef const char* (*fn_kiwi_res_form)(kiwi_res_h, int, int);
typedef const char* (*fn_kiwi_res_tag)(kiwi_res_h, int, int);
typedef int (*fn_kiwi_res_position)(kiwi_res_h, int, int);
typedef int (*fn_kiwi_res_length)(kiwi_res_h, int, int);
typedef int (*fn_kiwi_res_word_position)(kiwi_res_h, int, int);
typedef int (*fn_kiwi_res_sent_position)(kiwi_res_h, int, int);
typedef float (*fn_kiwi_res_score)(kiwi_res_h, int, int);
typedef float (*fn_kiwi_res_typo_cost)(kiwi_res_h, int, int);
typedef int (*fn_kiwi_res_close)(kiwi_res_h);

typedef struct {
  fn_kiwi_version kiwi_version;
  fn_kiwi_error kiwi_error;
  fn_kiwi_clear_error kiwi_clear_error;
  fn_kiwi_builder_init kiwi_builder_init;
  fn_kiwi_builder_close kiwi_builder_close;
  fn_kiwi_builder_add_word kiwi_builder_add_word;
  fn_kiwi_builder_build kiwi_builder_build;
  fn_kiwi_close kiwi_close;
  fn_kiwi_analyze kiwi_analyze;
  fn_kiwi_res_size kiwi_res_size;
  fn_kiwi_res_prob kiwi_res_prob;
  fn_kiwi_res_word_num kiwi_res_word_num;
  fn_kiwi_res_form kiwi_res_form;
  fn_kiwi_res_tag kiwi_res_tag;
  fn_kiwi_res_position kiwi_res_position;
  fn_kiwi_res_length kiwi_res_length;
  fn_kiwi_res_word_position kiwi_res_word_position;
  fn_kiwi_res_sent_position kiwi_res_sent_position;
  fn_kiwi_res_score kiwi_res_score;
  fn_kiwi_res_typo_cost kiwi_res_typo_cost;
  fn_kiwi_res_close kiwi_res_close;
} kiwi_api_t;

#if _WIN32
typedef HMODULE kiwi_lib_handle_t;
#else
typedef void* kiwi_lib_handle_t;
#endif

struct flutter_kiwi_ffi_handle {
  kiwi_builder_h builder;
  kiwi_h kiwi;
  int32_t default_match_options;
};

typedef struct string_builder {
  char* data;
  size_t length;
  size_t capacity;
} string_builder_t;

static KIWI_TLS char g_last_error[1024];
static kiwi_lib_handle_t g_kiwi_lib = NULL;
static kiwi_api_t g_kiwi_api;
static int g_kiwi_api_loaded = 0;

static void wrapper_clear_error(void) { g_last_error[0] = '\0'; }

static void wrapper_set_error(const char* message) {
  if (!message || !*message) {
    wrapper_clear_error();
    return;
  }
  snprintf(g_last_error, sizeof(g_last_error), "%s", message);
}

static void wrapper_set_error_from_kiwi(const char* fallback_message) {
  if (g_kiwi_api_loaded && g_kiwi_api.kiwi_error) {
    const char* kiwi_error = g_kiwi_api.kiwi_error();
    if (kiwi_error && *kiwi_error) {
      wrapper_set_error(kiwi_error);
      return;
    }
  }
  wrapper_set_error(fallback_message);
}

static int sb_init(string_builder_t* builder, size_t initial_capacity) {
  if (!builder) return -1;
  builder->data = (char*)malloc(initial_capacity);
  if (!builder->data) return -1;
  builder->length = 0;
  builder->capacity = initial_capacity;
  builder->data[0] = '\0';
  return 0;
}

static void sb_destroy(string_builder_t* builder) {
  if (!builder) return;
  free(builder->data);
  builder->data = NULL;
  builder->length = 0;
  builder->capacity = 0;
}

static int sb_reserve(string_builder_t* builder, size_t extra) {
  if (!builder) return -1;
  size_t needed = builder->length + extra + 1;
  if (needed <= builder->capacity) return 0;

  size_t next_capacity = builder->capacity * 2;
  while (next_capacity < needed) {
    next_capacity *= 2;
  }

  char* resized = (char*)realloc(builder->data, next_capacity);
  if (!resized) return -1;
  builder->data = resized;
  builder->capacity = next_capacity;
  return 0;
}

static int sb_append_n(string_builder_t* builder, const char* text, size_t length) {
  if (!builder || !text) return -1;
  if (sb_reserve(builder, length) != 0) return -1;
  memcpy(builder->data + builder->length, text, length);
  builder->length += length;
  builder->data[builder->length] = '\0';
  return 0;
}

static int sb_append(string_builder_t* builder, const char* text) {
  if (!text) return -1;
  return sb_append_n(builder, text, strlen(text));
}

static int sb_append_format(string_builder_t* builder, const char* format, ...) {
  va_list args;
  va_start(args, format);
  va_list args_copy;
  va_copy(args_copy, args);

  int needed = vsnprintf(NULL, 0, format, args_copy);
  va_end(args_copy);
  if (needed < 0) {
    va_end(args);
    return -1;
  }
  if (sb_reserve(builder, (size_t)needed) != 0) {
    va_end(args);
    return -1;
  }

  vsnprintf(builder->data + builder->length, builder->capacity - builder->length, format, args);
  builder->length += (size_t)needed;
  va_end(args);
  return 0;
}

static int sb_append_json_escaped(string_builder_t* builder, const char* text) {
  if (!builder || !text) return -1;
  for (const unsigned char* p = (const unsigned char*)text; *p; ++p) {
    switch (*p) {
      case '\"':
        if (sb_append(builder, "\\\"") != 0) return -1;
        break;
      case '\\':
        if (sb_append(builder, "\\\\") != 0) return -1;
        break;
      case '\b':
        if (sb_append(builder, "\\b") != 0) return -1;
        break;
      case '\f':
        if (sb_append(builder, "\\f") != 0) return -1;
        break;
      case '\n':
        if (sb_append(builder, "\\n") != 0) return -1;
        break;
      case '\r':
        if (sb_append(builder, "\\r") != 0) return -1;
        break;
      case '\t':
        if (sb_append(builder, "\\t") != 0) return -1;
        break;
      default:
        if (*p < 0x20) {
          if (sb_append_format(builder, "\\u%04x", *p) != 0) return -1;
        } else {
          if (sb_append_n(builder, (const char*)p, 1) != 0) return -1;
        }
    }
  }
  return 0;
}

static int load_symbol(void** output, const char* symbol_name) {
  if (!g_kiwi_lib) return -1;
  void* symbol = (void*)kiwi_dlsym(g_kiwi_lib, symbol_name);
  if (!symbol) {
    char message[256];
    snprintf(message, sizeof(message), "Missing symbol in Kiwi library: %s", symbol_name);
    wrapper_set_error(message);
    return -1;
  }
  *output = symbol;
  return 0;
}

static int load_kiwi_library_once(void) {
  if (g_kiwi_api_loaded) return 0;

  const char* override_path = getenv("FLUTTER_KIWI_NLP_LIBRARY_PATH");
  if (!override_path || !*override_path) {
    override_path = getenv("FLUTTER_KIWI_FFI_LIBRARY_PATH");
  }
  if (override_path && *override_path) {
    g_kiwi_lib = kiwi_dlopen(override_path);
    if (!g_kiwi_lib) {
      char message[512];
      snprintf(
          message,
          sizeof(message),
          "Failed to load Kiwi library from FLUTTER_KIWI_NLP_LIBRARY_PATH (legacy: FLUTTER_KIWI_FFI_LIBRARY_PATH): %s",
          override_path);
      wrapper_set_error(message);
      return -1;
    }
  } else {
#if _WIN32
    static const char* candidates[] = {"kiwi.dll", "libkiwi.dll", NULL};
#elif __APPLE__
    static const char* candidates[] = {
        "libkiwi.dylib",
        "kiwi.dylib",
        "@rpath/libkiwi.dylib",
        "@loader_path/libkiwi.dylib",
        "@loader_path/../Frameworks/libkiwi.dylib",
        "Kiwi.framework/Kiwi",
        "@rpath/Kiwi.framework/Kiwi",
        "@loader_path/Kiwi.framework/Kiwi",
        "@loader_path/../Frameworks/Kiwi.framework/Kiwi",
        "kiwi.framework/kiwi",
        NULL};
#else
    static const char* candidates[] = {"libkiwi.so", "kiwi.so", "./libkiwi.so", NULL};
#endif
    for (int i = 0; candidates[i] != NULL; ++i) {
      g_kiwi_lib = kiwi_dlopen(candidates[i]);
      if (g_kiwi_lib) break;
    }
    if (!g_kiwi_lib) {
      wrapper_set_error(
          "Failed to load Kiwi dynamic library. Set FLUTTER_KIWI_NLP_LIBRARY_PATH (legacy: FLUTTER_KIWI_FFI_LIBRARY_PATH).");
      return -1;
    }
  }

  if (load_symbol((void**)&g_kiwi_api.kiwi_version, "kiwi_version") != 0 ||
      load_symbol((void**)&g_kiwi_api.kiwi_error, "kiwi_error") != 0 ||
      load_symbol((void**)&g_kiwi_api.kiwi_clear_error, "kiwi_clear_error") != 0 ||
      load_symbol((void**)&g_kiwi_api.kiwi_builder_init, "kiwi_builder_init") != 0 ||
      load_symbol((void**)&g_kiwi_api.kiwi_builder_close, "kiwi_builder_close") != 0 ||
      load_symbol((void**)&g_kiwi_api.kiwi_builder_add_word, "kiwi_builder_add_word") != 0 ||
      load_symbol((void**)&g_kiwi_api.kiwi_builder_build, "kiwi_builder_build") != 0 ||
      load_symbol((void**)&g_kiwi_api.kiwi_close, "kiwi_close") != 0 ||
      load_symbol((void**)&g_kiwi_api.kiwi_analyze, "kiwi_analyze") != 0 ||
      load_symbol((void**)&g_kiwi_api.kiwi_res_size, "kiwi_res_size") != 0 ||
      load_symbol((void**)&g_kiwi_api.kiwi_res_prob, "kiwi_res_prob") != 0 ||
      load_symbol((void**)&g_kiwi_api.kiwi_res_word_num, "kiwi_res_word_num") != 0 ||
      load_symbol((void**)&g_kiwi_api.kiwi_res_form, "kiwi_res_form") != 0 ||
      load_symbol((void**)&g_kiwi_api.kiwi_res_tag, "kiwi_res_tag") != 0 ||
      load_symbol((void**)&g_kiwi_api.kiwi_res_position, "kiwi_res_position") != 0 ||
      load_symbol((void**)&g_kiwi_api.kiwi_res_length, "kiwi_res_length") != 0 ||
      load_symbol((void**)&g_kiwi_api.kiwi_res_word_position, "kiwi_res_word_position") != 0 ||
      load_symbol((void**)&g_kiwi_api.kiwi_res_sent_position, "kiwi_res_sent_position") != 0 ||
      load_symbol((void**)&g_kiwi_api.kiwi_res_score, "kiwi_res_score") != 0 ||
      load_symbol((void**)&g_kiwi_api.kiwi_res_typo_cost, "kiwi_res_typo_cost") != 0 ||
      load_symbol((void**)&g_kiwi_api.kiwi_res_close, "kiwi_res_close") != 0) {
    if (g_kiwi_lib) {
      kiwi_dlclose(g_kiwi_lib);
      g_kiwi_lib = NULL;
    }
    memset(&g_kiwi_api, 0, sizeof(g_kiwi_api));
    g_kiwi_api_loaded = 0;
    return -1;
  }

  g_kiwi_api_loaded = 1;
  return 0;
}

static int rebuild_kiwi_instance(flutter_kiwi_ffi_handle_t* handle) {
  if (!handle || !handle->builder) {
    wrapper_set_error("Invalid handle.");
    return -1;
  }

  kiwi_h next = g_kiwi_api.kiwi_builder_build(handle->builder, NULL, 0.0f);
  if (!next) {
    wrapper_set_error_from_kiwi("Failed to build Kiwi analyzer.");
    return -1;
  }

  if (handle->kiwi) {
    g_kiwi_api.kiwi_close(handle->kiwi);
  }
  handle->kiwi = next;
  return 0;
}

FFI_PLUGIN_EXPORT flutter_kiwi_ffi_handle_t* flutter_kiwi_ffi_init(
    const char* model_path,
    int32_t num_threads,
    int32_t build_options,
    int32_t match_options) {
  wrapper_clear_error();
  if (load_kiwi_library_once() != 0) return NULL;

  if (g_kiwi_api.kiwi_clear_error) {
    g_kiwi_api.kiwi_clear_error();
  }

  const char* env_model_path = getenv("FLUTTER_KIWI_NLP_MODEL_PATH");
  if (!env_model_path || !*env_model_path) {
    env_model_path = getenv("FLUTTER_KIWI_FFI_MODEL_PATH");
  }
  const char* resolved_model_path =
      (model_path && *model_path) ? model_path : env_model_path;
  if (!resolved_model_path || !*resolved_model_path) {
    wrapper_set_error(
        "Model path is required. Pass modelPath or set FLUTTER_KIWI_NLP_MODEL_PATH (legacy: FLUTTER_KIWI_FFI_MODEL_PATH).");
    return NULL;
  }

  flutter_kiwi_ffi_handle_t* handle =
      (flutter_kiwi_ffi_handle_t*)calloc(1, sizeof(flutter_kiwi_ffi_handle_t));
  if (!handle) {
    wrapper_set_error("Failed to allocate analyzer handle.");
    return NULL;
  }

  int build_opts = build_options == 0 ? KIWI_BUILD_DEFAULT : build_options;
  handle->builder = g_kiwi_api.kiwi_builder_init(
      resolved_model_path,
      num_threads,
      build_opts,
      KIWI_DIALECT_STANDARD);
  if (!handle->builder) {
    wrapper_set_error_from_kiwi("Failed to initialize Kiwi builder.");
    free(handle);
    return NULL;
  }

  handle->default_match_options =
      match_options == 0 ? KIWI_MATCH_ALL_WITH_NORMALIZING : match_options;

  if (rebuild_kiwi_instance(handle) != 0) {
    g_kiwi_api.kiwi_builder_close(handle->builder);
    free(handle);
    return NULL;
  }

  return handle;
}

FFI_PLUGIN_EXPORT int32_t flutter_kiwi_ffi_close(flutter_kiwi_ffi_handle_t* handle) {
  wrapper_clear_error();
  if (!handle) {
    wrapper_set_error("Invalid handle.");
    return -1;
  }

  if (g_kiwi_api_loaded && g_kiwi_api.kiwi_clear_error) {
    g_kiwi_api.kiwi_clear_error();
  }

  if (handle->kiwi && g_kiwi_api_loaded && g_kiwi_api.kiwi_close) {
    g_kiwi_api.kiwi_close(handle->kiwi);
  }
  if (handle->builder && g_kiwi_api_loaded && g_kiwi_api.kiwi_builder_close) {
    g_kiwi_api.kiwi_builder_close(handle->builder);
  }
  free(handle);
  return 0;
}

FFI_PLUGIN_EXPORT char* flutter_kiwi_ffi_analyze_json(
    flutter_kiwi_ffi_handle_t* handle,
    const char* text,
    int32_t top_n,
    int32_t match_options) {
  wrapper_clear_error();
  if (!handle || !handle->kiwi) {
    wrapper_set_error("Invalid analyzer handle.");
    return NULL;
  }
  if (!text) {
    wrapper_set_error("Text must not be null.");
    return NULL;
  }

  if (g_kiwi_api.kiwi_clear_error) {
    g_kiwi_api.kiwi_clear_error();
  }

  kiwi_analyze_option_t options;
  options.match_options = match_options == 0 ? handle->default_match_options : match_options;
  options.blocklist = NULL;
  options.open_ending = 0;
  options.allowed_dialects = KIWI_DIALECT_ALL;
  options.dialect_cost = 3.0f;

  kiwi_res_h res =
      g_kiwi_api.kiwi_analyze(handle->kiwi, text, top_n > 0 ? top_n : 1, options, NULL);
  if (!res) {
    wrapper_set_error_from_kiwi("Kiwi analyze failed.");
    return NULL;
  }

  string_builder_t builder;
  if (sb_init(&builder, 1024) != 0) {
    g_kiwi_api.kiwi_res_close(res);
    wrapper_set_error("Failed to allocate output buffer.");
    return NULL;
  }

  int failed = 0;
  int candidate_count = g_kiwi_api.kiwi_res_size(res);
  if (candidate_count < 0) {
    failed = 1;
    wrapper_set_error_from_kiwi("Invalid Kiwi result set.");
  }

  if (!failed) failed |= sb_append(&builder, "{\"candidates\":[");

  for (int i = 0; !failed && i < candidate_count; ++i) {
    if (i > 0) failed |= sb_append(&builder, ",");
    failed |= sb_append_format(&builder, "{\"probability\":%.8g,\"tokens\":[", g_kiwi_api.kiwi_res_prob(res, i));

    int token_count = g_kiwi_api.kiwi_res_word_num(res, i);
    if (token_count < 0) {
      failed = 1;
      wrapper_set_error_from_kiwi("Invalid Kiwi token count.");
      break;
    }

    for (int j = 0; !failed && j < token_count; ++j) {
      if (j > 0) failed |= sb_append(&builder, ",");

      const char* form = g_kiwi_api.kiwi_res_form(res, i, j);
      const char* tag = g_kiwi_api.kiwi_res_tag(res, i, j);
      int start = g_kiwi_api.kiwi_res_position(res, i, j);
      int length = g_kiwi_api.kiwi_res_length(res, i, j);
      int word_position = g_kiwi_api.kiwi_res_word_position(res, i, j);
      int sent_position = g_kiwi_api.kiwi_res_sent_position(res, i, j);
      float score = g_kiwi_api.kiwi_res_score(res, i, j);
      float typo_cost = g_kiwi_api.kiwi_res_typo_cost(res, i, j);

      if (start < 0 || length < 0 || word_position < 0 || sent_position < 0) {
        failed = 1;
        wrapper_set_error_from_kiwi("Invalid token metadata.");
        break;
      }

      failed |= sb_append(&builder, "{\"form\":\"");
      failed |= sb_append_json_escaped(&builder, form ? form : "");
      failed |= sb_append(&builder, "\",\"tag\":\"");
      failed |= sb_append_json_escaped(&builder, tag ? tag : "");
      failed |= sb_append_format(
          &builder,
          "\",\"start\":%d,\"length\":%d,\"wordPosition\":%d,\"sentPosition\":%d,\"score\":%.8g,\"typoCost\":%.8g}",
          start,
          length,
          word_position,
          sent_position,
          score,
          typo_cost);
    }

    failed |= sb_append(&builder, "]}");
  }

  if (!failed) failed |= sb_append(&builder, "]}");

  g_kiwi_api.kiwi_res_close(res);

  if (failed) {
    if (!g_last_error[0]) {
      wrapper_set_error("Failed to build analyze JSON.");
    }
    sb_destroy(&builder);
    return NULL;
  }

  return builder.data;
}

FFI_PLUGIN_EXPORT int32_t flutter_kiwi_ffi_add_user_word(
    flutter_kiwi_ffi_handle_t* handle,
    const char* word,
    const char* tag,
    float score) {
  wrapper_clear_error();
  if (!handle || !handle->builder) {
    wrapper_set_error("Invalid analyzer handle.");
    return -1;
  }
  if (!word || !*word) {
    wrapper_set_error("Word must not be empty.");
    return -1;
  }
  if (!tag || !*tag) {
    wrapper_set_error("Tag must not be empty.");
    return -1;
  }

  if (g_kiwi_api.kiwi_clear_error) {
    g_kiwi_api.kiwi_clear_error();
  }

  int status = g_kiwi_api.kiwi_builder_add_word(handle->builder, word, tag, score);
  if (status < 0) {
    wrapper_set_error_from_kiwi("Failed to add user word.");
    return -1;
  }
  if (rebuild_kiwi_instance(handle) != 0) {
    return -1;
  }
  return 0;
}

FFI_PLUGIN_EXPORT void flutter_kiwi_ffi_free_string(char* value) { free(value); }

FFI_PLUGIN_EXPORT const char* flutter_kiwi_ffi_last_error(void) {
  if (!*g_last_error) return NULL;
  return g_last_error;
}

FFI_PLUGIN_EXPORT const char* flutter_kiwi_ffi_version(void) {
  if (g_kiwi_api_loaded && g_kiwi_api.kiwi_version) {
    return g_kiwi_api.kiwi_version();
  }
  return "flutter_kiwi_ffi-wrapper";
}
