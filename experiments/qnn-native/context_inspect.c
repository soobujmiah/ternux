/* Independently written adapter for public QNN System C API prefixes.
 * Reads a passed anonymous FD; never extracts a model or executes an HTP graph.
 */
#include <dlfcn.h>
#include <inttypes.h>
#include <stdint.h>
#include <stdio.h>
#include <stdarg.h>
#include <stdlib.h>
#include <string.h>
#include <sys/mman.h>
#include <sys/stat.h>
#include <unistd.h>

typedef uint64_t (*providers_fn)(const void ***, uint32_t *);
typedef struct { uint32_t major, minor, patch; } version;
typedef struct { uint32_t id; const char *name; version api; } system_prefix;
typedef uint64_t (*create_fn)(void **);
typedef uint64_t (*info_fn)(void *, void *, uint64_t, const void **, uint64_t *);
typedef uint64_t (*free_fn)(void *);
typedef struct { create_fn create; info_fn info; void *metadata; free_fn free; } system_api;
typedef struct { uint32_t id; const char *build; version core, backend; const char *soc; } binary_prefix;
typedef struct { uint32_t tag; binary_prefix info; } tagged_binary_prefix;
typedef struct { uint32_t id; const char *name; version core, backend; } htp_prefix;
typedef struct { version core, backend; } combined_version;
typedef uint64_t (*backend_create_fn)(void *, const void **, void **);
typedef uint64_t (*backend_free_fn)(void *);
typedef uint64_t (*version_fn)(combined_version *);
typedef uint64_t (*from_binary_fn)(void *, void *, const void **, const void *, uint64_t, void **, void *);
typedef uint64_t (*context_free_fn)(void *, void *);
typedef void (*log_callback)(const char *, int32_t, uint64_t, va_list);
typedef uint64_t (*log_create_fn)(log_callback, int32_t, void **);
typedef struct {
    void *property;
    backend_create_fn create;
    void *set_config;
    version_fn get_version;
    void *get_build, *register_package, *get_operations, *validate;
    backend_free_fn free;
    void *context_create, *context_set_config, *context_binary_size, *context_binary;
    from_binary_fn from_binary;
    context_free_fn free_context;
    void *graph_tensor_fields[10];
    log_create_fn log_create;
    void *log_set;
    backend_free_fn log_free;
    void *profile_memory_platform_fields[12];
    backend_create_fn device_create;
    void *device_set, *device_info;
    backend_free_fn device_free;
} htp_api;

static void qnn_log(const char *fmt, int32_t level, uint64_t timestamp, va_list args) {
    (void)timestamp;
    fprintf(stderr, "QNN[%d] ", level);
    vfprintf(stderr, fmt, args);
    fputc('\n', stderr);
}

static void quoted(const char *text) {
    putchar('"');
    if (text) for (; *text; ++text) {
        unsigned char c = (unsigned char)*text;
        if (c == '"' || c == '\\') { putchar('\\'); putchar(c); }
        else if (c < 32) printf("\\u%04x", c);
        else putchar(c);
    }
    putchar('"');
}

static int load_htp(void *bytes, uint64_t size) {
    void *lib = dlopen("/vendor/lib64/libQnnHtp.so", RTLD_NOW | RTLD_LOCAL);
    if (!lib) return 2;
    int result = 2;
    providers_fn get = (providers_fn)dlsym(lib, "QnnInterface_getProviders");
    const void **providers = NULL;
    uint32_t count = 0;
    if (!get || get(&providers, &count) || count != 1 || !providers || !providers[0]) goto done;
    htp_prefix prefix;
    memcpy(&prefix, providers[0], sizeof(prefix));
    if (prefix.id != 6 || prefix.core.major != 2 || prefix.core.minor != 22) goto done;
    htp_api api;
    memcpy(&api, (const unsigned char *)providers[0] + sizeof(prefix), sizeof(api));
    combined_version checked = {0};
    if (!api.get_version || api.get_version(&checked) || memcmp(&checked, &prefix.core, sizeof(checked)) ||
        !api.create || !api.free || !api.from_binary || !api.free_context) goto done;
    void *backend = NULL;
    void *logger = NULL;
    if (api.log_create && api.log_free) {
        uint64_t logged = api.log_create(qnn_log, 4, &logger);
        printf("{\"stage\":\"qnn_logger_create\",\"status\":%" PRIu64 "}\n", logged);
    }
    uint64_t status = api.create(logger, NULL, &backend);
    printf("{\"stage\":\"htp_backend_create\",\"status\":%" PRIu64 ",\"handle_present\":%s}\n", status, backend ? "true" : "false");
    if (!status && backend) {
        void *device = NULL;
        uint64_t device_status = api.device_create && api.device_free ? api.device_create(logger, NULL, &device) : UINT64_MAX;
        printf("{\"stage\":\"htp_device_create\",\"status\":%" PRIu64 ",\"handle_present\":%s}\n", device_status, device ? "true" : "false");
        void *context = NULL;
        status = device_status == 0 ? api.from_binary(backend, device, NULL, bytes, size, &context, NULL) : device_status;
        printf("{\"stage\":\"htp_context_from_binary\",\"status\":%" PRIu64 ",\"error_code\":%u,"
               "\"handle_present\":%s,\"inference\":\"unverified\"}\n", status,
               (unsigned)(status & 65535), context ? "true" : "false");
        result = !status && context ? 0 : 2;
        if (context) {
            uint64_t freed = api.free_context(context, NULL);
            printf("{\"stage\":\"htp_context_free\",\"status\":%" PRIu64 "}\n", freed);
            if (freed) result = 2;
        }
        if (device) {
            uint64_t freed = api.device_free(device);
            printf("{\"stage\":\"htp_device_free\",\"status\":%" PRIu64 "}\n", freed);
            if (freed) result = 2;
        }
    }
    if (backend) {
        uint64_t freed = api.free(backend);
        printf("{\"stage\":\"htp_backend_free\",\"status\":%" PRIu64 "}\n", freed);
        if (freed) result = 2;
    }
    if (logger) {
        uint64_t freed = api.log_free(logger);
        printf("{\"stage\":\"qnn_logger_free\",\"status\":%" PRIu64 "}\n", freed);
        if (freed) result = 2;
    }
done:
    /* QNN's HTP runtime keeps process-global transport state. Retain the
     * library until this short-lived helper exits after explicit handle
     * cleanup; unloading it here crashes the measured vendor build. */
    return result;
}

int main(int argc, char **argv) {
    setbuf(stdout, NULL);
    if ((argc != 3 && argc != 4) || strcmp(argv[1], "--fd") ||
        (argc == 4 && strcmp(argv[3], "--load-htp"))) return 2;
    char *end = NULL;
    long supplied = strtol(argv[2], &end, 10);
    if (!end || *end || supplied < 0 || supplied > INT32_MAX) return 2;
    int fd = (int)supplied;
    struct stat st;
    if (fstat(fd, &st) || st.st_size <= 0 || st.st_size > (int64_t)1536 * 1024 * 1024) return 2;
    void *bytes = mmap(NULL, (size_t)st.st_size, PROT_READ, MAP_PRIVATE, fd, 0);
    if (bytes == MAP_FAILED) return 2;
    void *lib = dlopen("/vendor/lib64/libQnnSystem.so", RTLD_NOW | RTLD_LOCAL);
    int result = 2;
    if (!lib) { puts("{\"stage\":\"system_library\",\"loaded\":false}"); goto done; }
    providers_fn get = (providers_fn)dlsym(lib, "QnnSystemInterface_getProviders");
    const void **providers = NULL;
    uint32_t count = 0;
    if (!get || get(&providers, &count) || count != 1 || !providers || !providers[0]) goto done;
    system_prefix prefix;
    memcpy(&prefix, providers[0], sizeof(prefix));
    printf("{\"stage\":\"qnn_system_api\",\"version\":\"%u.%u.%u\"}\n", prefix.api.major, prefix.api.minor, prefix.api.patch);
    if (prefix.api.major != 1) goto done;
    system_api api;
    memcpy(&api, (const unsigned char *)providers[0] + sizeof(prefix), sizeof(api));
    if (!api.create || !api.info || !api.free) goto done;
    void *context = NULL;
    uint64_t created = api.create(&context);
    printf("{\"stage\":\"system_context_create\",\"status\":%" PRIu64 ",\"handle_present\":%s}\n", created, context ? "true" : "false");
    if (!created && context) {
        const void *metadata = NULL;
        uint64_t metadata_size = 0;
        uint64_t status = api.info(context, bytes, (uint64_t)st.st_size, &metadata, &metadata_size);
        uint32_t metadata_version = 0;
        if (!status && metadata) memcpy(&metadata_version, metadata, 4);
        printf("{\"stage\":\"qnn_context_binary_info\",\"status\":%" PRIu64 ",\"metadata_present\":%s,"
               "\"metadata_bytes\":%" PRIu64 ",\"metadata_version\":%u,\"inference\":\"unverified\"}\n",
               status, metadata ? "true" : "false", metadata_size, metadata_version);
        result = !status && metadata ? 0 : 2;
        if (!status && metadata && metadata_version >= 1 && metadata_version <= 3) {
            tagged_binary_prefix decoded;
            memcpy(&decoded, metadata, sizeof(decoded));
            printf("{\"stage\":\"context_compilation_identity\",\"backend_id\":%u,"
                   "\"core_api\":\"%u.%u.%u\",\"backend_api\":\"%u.%u.%u\",\"build\":",
                   decoded.info.id, decoded.info.core.major, decoded.info.core.minor, decoded.info.core.patch,
                   decoded.info.backend.major, decoded.info.backend.minor, decoded.info.backend.patch);
            quoted(decoded.info.build); printf(",\"soc_version\":"); quoted(decoded.info.soc); puts("}");
        }
    }
    if (context) {
        uint64_t freed = api.free(context);
        printf("{\"stage\":\"system_context_free\",\"status\":%" PRIu64 "}\n", freed);
        if (freed) result = 2;
    }
    if (!result && argc == 4) result = load_htp(bytes, (uint64_t)st.st_size);
done:
    if (lib) dlclose(lib);
    munmap(bytes, (size_t)st.st_size);
    return result;
}
