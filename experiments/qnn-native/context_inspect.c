/* Independently written adapter for public QNN System C API prefixes.
 * Reads a passed anonymous FD; never extracts a model. Graph execution is
 * opt-in and remains an experiment until an independent output oracle exists.
 */
#include <dlfcn.h>
#include <inttypes.h>
#include <stdbool.h>
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
/* Public QnnSystemContext_BinaryInfoV3/GraphInfoV3 field prefix. This bounded
 * adapter is pinned to the observed 2.28 binary metadata, not a general SDK. */
typedef struct {
    binary_prefix identity;
    version blob_version;
    uint64_t blob_size;
    uint32_t context_tensor_count;
    void *context_tensors;
    uint32_t graph_count;
    const void *graphs;
} binary_v3_prefix;
typedef struct { uint32_t tag; binary_v3_prefix info; } tagged_binary_v3_prefix;
typedef struct {
    uint32_t tag;
    const char *name;
    uint32_t input_count;
    const void *inputs;
    uint32_t output_count;
    const void *outputs;
} graph_v3_prefix;

static void quoted(const char *text);

static void tensor_summaries(const char *role, const void *array, uint32_t count) {
    /* 2.36 public Qnn_Tensor_t layout gives 144-byte entries. Check every
     * observed version/rank before interpreting the older 2.28 context. */
    if (!array || count > 8) return;
    const unsigned char *base = (const unsigned char *)array;
    for (uint32_t index = 0; index < count; ++index) {
        const unsigned char *entry = base + (size_t)index * 144;
        uint32_t tensor_version, id, type, format, datatype, rank;
        const char *name;
        const uint32_t *dims;
        memcpy(&tensor_version, entry, 4);
        memcpy(&id, entry + 8, 4);
        memcpy(&name, entry + 16, 8);
        memcpy(&type, entry + 24, 4);
        memcpy(&format, entry + 28, 4);
        memcpy(&datatype, entry + 32, 4);
        memcpy(&rank, entry + 80, 4);
        memcpy(&dims, entry + 88, 8);
        if (tensor_version < 1 || tensor_version > 2 || rank > 8 || (rank && !dims)) break;
        printf("{\"stage\":\"qnn_context_tensor_shape\",\"role\":"); quoted(role);
        printf(",\"index\":%u,\"version\":%u,\"id\":%u,\"name\":", index, tensor_version, id);
        quoted(name);
        printf(",\"type\":%u,\"format\":%u,\"datatype\":%u,\"dims\":[", type, format, datatype);
        for (uint32_t dimension = 0; dimension < rank; ++dimension) {
            uint32_t size = dims[dimension];
            if (dimension) putchar(',');
            printf("%u", size);
        }
        puts("]}");
    }
}
typedef struct { uint32_t id; const char *name; version core, backend; } htp_prefix;
typedef struct { version core, backend; } combined_version;
typedef uint64_t (*backend_create_fn)(void *, const void **, void **);
typedef uint64_t (*backend_free_fn)(void *);
typedef uint64_t (*version_fn)(combined_version *);
typedef uint64_t (*from_binary_fn)(void *, void *, const void **, const void *, uint64_t, void **, void *);
typedef uint64_t (*context_free_fn)(void *, void *);
typedef uint64_t (*graph_retrieve_fn)(void *, const char *, void **);
typedef uint64_t (*graph_execute_fn)(void *, const void *, uint32_t, void *, uint32_t, void *, void *);
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
    void *graph_create, *graph_create_subgraph, *graph_set_config, *graph_add_node, *graph_finalize;
    graph_retrieve_fn graph_retrieve;
    graph_execute_fn graph_execute;
    void *graph_execute_async;
    void *tensor_create_context, *tensor_create_graph;
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

static bool tensor_matches(const unsigned char *entry, const char *expected_name,
                           uint32_t expected_type, const uint32_t expected_dims[4]) {
    uint32_t version, type, format, datatype, rank;
    const char *name;
    const uint32_t *dims;
    memcpy(&version, entry, 4);
    memcpy(&name, entry + 16, 8);
    memcpy(&type, entry + 24, 4);
    memcpy(&format, entry + 28, 4);
    memcpy(&datatype, entry + 32, 4);
    memcpy(&rank, entry + 80, 4);
    memcpy(&dims, entry + 88, 8);
    return version == 1 && name && !strcmp(name, expected_name) &&
           type == expected_type && format == 0 && datatype == 0x0416 &&
           rank == 4 && dims && !memcmp(dims, expected_dims, 4 * sizeof(uint32_t));
}

static void set_client_buffer(unsigned char *tensor, void *data, uint32_t bytes) {
    /* Public Qnn_TensorV1_t layout: union starts at +8, memType +96,
     * clientBuf.data +104 and clientBuf.dataSize +112 on AArch64. */
    uint32_t raw = 0;
    memcpy(tensor + 96, &raw, 4);
    memcpy(tensor + 104, &data, 8);
    memcpy(tensor + 112, &bytes, 4);
}

static uint64_t digest64(const unsigned char *data, size_t size) {
    uint64_t hash = UINT64_C(14695981039346656037);
    for (size_t i = 0; i < size; ++i) {
        hash ^= data[i];
        hash *= UINT64_C(1099511628211);
    }
    return hash;
}

static int execute_vae_twice(graph_execute_fn execute, void *handle, const graph_v3_prefix *metadata) {
    const uint32_t input_dims[4] = {1, 3, 512, 512};
    const uint32_t output_dims[4] = {1, 4, 64, 64};
    const uint32_t input_bytes = 1 * 3 * 512 * 512 * sizeof(uint16_t);
    const uint32_t output_bytes = 1 * 4 * 64 * 64 * sizeof(uint16_t);
    if (!execute || !handle || !metadata || metadata->input_count != 1 ||
        metadata->output_count != 2 || !metadata->inputs || !metadata->outputs ||
        !metadata->name || strcmp(metadata->name, "model")) return 2;
    const unsigned char *input_template = (const unsigned char *)metadata->inputs;
    const unsigned char *output_template = (const unsigned char *)metadata->outputs;
    if (!tensor_matches(input_template, "input", 0, input_dims) ||
        !tensor_matches(output_template, "mean", 1, output_dims) ||
        !tensor_matches(output_template + 144, "std", 1, output_dims)) {
        puts("{\"stage\":\"vae_execute_preflight\",\"accepted\":false}");
        return 2;
    }
    unsigned char input_tensor[144], output_tensors[2 * 144];
    memcpy(input_tensor, input_template, sizeof(input_tensor));
    memcpy(output_tensors, output_template, sizeof(output_tensors));
    unsigned char *input_data = calloc(1, input_bytes);
    unsigned char *mean_data = malloc(output_bytes);
    unsigned char *std_data = malloc(output_bytes);
    unsigned char *mean_first = malloc(output_bytes);
    unsigned char *std_first = malloc(output_bytes);
    int result = 2;
    if (!input_data || !mean_data || !std_data || !mean_first || !std_first) goto cleanup;
    set_client_buffer(input_tensor, input_data, input_bytes);
    set_client_buffer(output_tensors, mean_data, output_bytes);
    set_client_buffer(output_tensors + 144, std_data, output_bytes);
    puts("{\"stage\":\"vae_execute_preflight\",\"accepted\":true,\"input_pattern\":\"raw_uint16_zero\",\"oracle\":\"repeat_only\"}");
    for (int run = 1; run <= 2; ++run) {
        memset(mean_data, 0xa5, output_bytes);
        memset(std_data, 0xa5, output_bytes);
        uint64_t status = execute(handle, input_tensor, 1, output_tensors, 2, NULL, NULL);
        size_t mean_changed = 0, std_changed = 0;
        for (size_t i = 0; i < output_bytes; ++i) {
            mean_changed += mean_data[i] != 0xa5;
            std_changed += std_data[i] != 0xa5;
        }
        printf("{\"stage\":\"vae_graph_execute\",\"run\":%d,\"status\":%" PRIu64
               ",\"mean_changed_bytes\":%zu,\"std_changed_bytes\":%zu,"
               "\"mean_digest64\":\"%016" PRIx64 "\",\"std_digest64\":\"%016" PRIx64 "\"}\n",
               run, status, mean_changed, std_changed,
               digest64(mean_data, output_bytes), digest64(std_data, output_bytes));
        if (status || !mean_changed || !std_changed) goto cleanup;
        if (run == 1) {
            memcpy(mean_first, mean_data, output_bytes);
            memcpy(std_first, std_data, output_bytes);
        } else {
            bool exact = !memcmp(mean_first, mean_data, output_bytes) &&
                         !memcmp(std_first, std_data, output_bytes);
            printf("{\"stage\":\"vae_repeat_exact\",\"equal\":%s,\"known_output\":false}\n",
                   exact ? "true" : "false");
            if (!exact) goto cleanup;
        }
    }
    result = 0;
cleanup:
    free(input_data);
    free(mean_data);
    free(std_data);
    free(mean_first);
    free(std_first);
    return result;
}

static int load_htp(void *bytes, uint64_t size, const graph_v3_prefix *metadata, bool execute_graph) {
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
            void *graph = NULL;
            uint64_t retrieved = api.graph_retrieve ? api.graph_retrieve(context, "model", &graph) : UINT64_MAX;
            printf("{\"stage\":\"htp_graph_retrieve\",\"status\":%" PRIu64 ",\"handle_present\":%s}\n",
                   retrieved, graph ? "true" : "false");
            if (retrieved || !graph) result = 2;
            if (!retrieved && graph && execute_graph) {
                result = execute_vae_twice(api.graph_execute, graph, metadata);
            }
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
        (argc == 4 && strcmp(argv[3], "--load-htp") && strcmp(argv[3], "--execute-htp"))) return 2;
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
    graph_v3_prefix graph_info = {0};
    bool graph_info_present = false;
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
            if (metadata_version == 3 && decoded.info.id == 6 &&
                decoded.info.core.major == 2 && decoded.info.core.minor == 21 &&
                decoded.info.backend.major == 5 && decoded.info.backend.minor == 28) {
                tagged_binary_v3_prefix full;
                memcpy(&full, metadata, sizeof(full));
                printf("{\"stage\":\"qnn_context_graph_counts\",\"count\":%u,\"context_tensors\":%u}\n",
                       full.info.graph_count, full.info.context_tensor_count);
                if (full.info.graph_count == 1 && full.info.graphs) {
                    graph_v3_prefix graph;
                    memcpy(&graph, full.info.graphs, sizeof(graph));
                    if (graph.tag == 3 && graph.input_count <= 32 && graph.output_count <= 32) {
                        graph_info = graph;
                        graph_info_present = true;
                        printf("{\"stage\":\"qnn_context_graph_io_counts\",\"index\":0,\"name\":");
                        quoted(graph.name);
                        printf(",\"inputs\":%u,\"outputs\":%u}\n", graph.input_count, graph.output_count);
                        tensor_summaries("input", graph.inputs, graph.input_count);
                        tensor_summaries("output", graph.outputs, graph.output_count);
                    }
                }
            }
        }
    }
    if (!result && argc == 4) {
        bool execute_graph = !strcmp(argv[3], "--execute-htp");
        if (execute_graph && !graph_info_present) {
            puts("{\"stage\":\"vae_execute_preflight\",\"accepted\":false,\"reason\":\"missing_graph_metadata\"}");
            result = 2;
        } else {
            result = load_htp(bytes, (uint64_t)st.st_size,
                              graph_info_present ? &graph_info : NULL, execute_graph);
        }
    }
    if (context) {
        uint64_t freed = api.free(context);
        printf("{\"stage\":\"system_context_free\",\"status\":%" PRIu64 "}\n", freed);
        if (freed) result = 2;
    }
done:
    if (lib) dlclose(lib);
    munmap(bytes, (size_t)st.st_size);
    return result;
}
