/* Android/Bionic helper. Discovery only: no context loading or inference.
 * Only the documented API prefix is inspected; model execution needs matching SDK headers.
 * No proprietary libraries or model bytes are copied by this program.
 */
#include <dlfcn.h>
#include <inttypes.h>
#include <stdint.h>
#include <stdio.h>
#include <string.h>

typedef uint64_t (*provider_fn)(const void ***, uint32_t *);
typedef struct { uint32_t major, minor, patch; } api_version;
typedef struct {
    uint32_t backend_id;
    const char *name;
    api_version core, backend;
} interface_prefix;
typedef struct { api_version core, backend; } combined_version;
typedef uint64_t (*get_version_fn)(combined_version *);
typedef uint64_t (*get_build_fn)(const char **);
typedef uint64_t (*create_backend_fn)(void *, const void **, void **);
typedef uint64_t (*free_backend_fn)(void *);

/* Public QnnInterface initial fields; only use after validating API 2.22.
 * Later SDK-specific fields/tensors deliberately require matching SDK headers.
 */
typedef struct {
    void *property_has_capability;
    create_backend_fn create;
    void *set_config;
    get_version_fn get_version;
    get_build_fn get_build;
    void *register_package, *get_operations, *validate_operation;
    free_backend_fn free;
} backend_api_prefix;

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

static int inspect(const char *path, const char *symbol) {
    void *lib = dlopen(path, RTLD_NOW | RTLD_LOCAL);
    printf("{\"stage\":\"native_qnn_discovery\",\"library\":");
    quoted(path);
    if (!lib) {
        printf(",\"loaded\":false,\"error\":"); quoted(dlerror());
        puts(",\"inference\":\"unverified\"}");
        return 2;
    }
    dlerror();
    provider_fn get = (provider_fn)dlsym(lib, symbol);
    const char *err = dlerror();
    if (err || !get) {
        printf(",\"loaded\":true,\"symbol_found\":false,\"error\":");
        quoted(err); puts("}"); dlclose(lib); return 3;
    }
    const void **providers = NULL;
    uint32_t count = 0;
    uint64_t status = get(&providers, &count);
    printf(",\"loaded\":true,\"symbol_found\":true,\"provider_status\":%" PRIu64 ","
           "\"provider_count\":%u,\"provider_array_present\":%s,"
           "\"inference\":\"unverified\"}\n",
           status, count, providers ? "true" : "false");
    if (status == 0 && count == 1 && providers && providers[0] &&
        strcmp(symbol, "QnnInterface_getProviders") == 0) {
        interface_prefix prefix;
        memcpy(&prefix, providers[0], sizeof(prefix));
        printf("{\"stage\":\"htp_provider_api_version\",\"backend_id\":%u,"
               "\"core_api\":\"%u.%u.%u\",\"backend_api\":\"%u.%u.%u\"}\n",
               prefix.backend_id, prefix.core.major, prefix.core.minor, prefix.core.patch,
               prefix.backend.major, prefix.backend.minor, prefix.backend.patch);
        if (prefix.backend_id == 6 && prefix.core.major == 2 && prefix.core.minor == 22) {
            backend_api_prefix api;
            memcpy(&api, (const unsigned char *)providers[0] + sizeof(prefix), sizeof(api));
            combined_version checked = {0};
            uint64_t version_status = api.get_version ? api.get_version(&checked) : UINT64_MAX;
            printf("{\"stage\":\"htp_api_crosscheck\",\"status\":%" PRIu64 "}\n", version_status);
            if (!version_status && !memcmp(&checked, &prefix.core, sizeof(checked)) && api.create && api.free) {
                const char *build = NULL;
                uint64_t build_status = api.get_build ? api.get_build(&build) : UINT64_MAX;
                printf("{\"stage\":\"htp_runtime_build\",\"status\":%" PRIu64 ",\"build\":", build_status);
                quoted(build_status ? NULL : build); puts("}");
                void *backend = NULL;
                uint64_t created = api.create(NULL, NULL, &backend);
                printf("{\"stage\":\"htp_backend_create\",\"status\":%" PRIu64 ",\"handle_present\":%s}\n",
                       created, backend ? "true" : "false");
                if (backend) {
                    uint64_t freed = api.free(backend);
                    printf("{\"stage\":\"htp_backend_free\",\"status\":%" PRIu64 "}\n", freed);
                }
            }
        }
    }
    dlclose(lib);
    return status == 0 && count && providers ? 0 : 4;
}

int main(void) {
    puts("{\"helper\":\"ternux_qnn_native_probe\",\"abi\":\"android-bionic-arm64\","
         "\"model_loading\":\"not_attempted\"}");
    int htp = inspect("/vendor/lib64/libQnnHtp.so", "QnnInterface_getProviders");
    int system = inspect("/vendor/lib64/libQnnSystem.so", "QnnSystemInterface_getProviders");
    return htp ? htp : system;
}
