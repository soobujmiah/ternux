/* Independent, bounded QNN HTP known-answer graph probe for Android/Bionic.
 * Uses the public QNN v1 tensor/operator ABI; no SDK files or vendor binaries
 * are embedded. A release feature requires separate licensing and device gates.
 */
#include <dlfcn.h>
#include <inttypes.h>
#include <stddef.h>
#include <stdarg.h>
#include <stdint.h>
#include <stdio.h>
#include <string.h>

typedef struct { uint32_t major, minor, patch; } version;
typedef struct { uint32_t id; const char *name; version core, backend; } provider_prefix;
typedef struct { version core, backend; } combined_version;
typedef uint64_t (*providers_fn)(const void ***, uint32_t *);
typedef uint64_t (*create_fn)(void *, const void **, void **);
typedef uint64_t (*free_fn)(void *);
typedef uint64_t (*version_fn)(combined_version *);
typedef uint64_t (*context_create_fn)(void *, void *, const void **, void **);
typedef uint64_t (*context_free_fn)(void *, void *);
typedef uint64_t (*graph_create_fn)(void *, const char *, const void **, void **);
typedef uint64_t (*graph_finalize_fn)(void *, void *, void *);
typedef uint64_t (*graph_execute_fn)(void *, const void *, uint32_t, void *, uint32_t, void *, void *);
typedef uint64_t (*tensor_create_fn)(void *, void *);
typedef void (*log_callback)(const char *, int32_t, uint64_t, va_list);
typedef uint64_t (*log_create_fn)(log_callback, int32_t, void **);
struct op_config;

typedef struct {
    void *property;
    create_fn backend_create;
    void *backend_set_config;
    version_fn backend_get_version;
    void *backend_get_build, *backend_register_package, *backend_get_ops, *backend_validate;
    free_fn backend_free;
    context_create_fn context_create;
    void *context_set_config, *context_binary_size, *context_binary, *context_from_binary;
    context_free_fn context_free;
    graph_create_fn graph_create;
    void *graph_create_subgraph, *graph_set_config;
    uint64_t (*graph_add_node)(void *, struct op_config);
    graph_finalize_fn graph_finalize;
    void *graph_retrieve;
    graph_execute_fn graph_execute;
    void *graph_execute_async, *tensor_create_context;
    tensor_create_fn tensor_create_graph;
    log_create_fn log_create;
    void *log_set;
    free_fn log_free;
    void *profile_memory_platform_fields[12];
    create_fn device_create;
    void *device_set, *device_info;
    free_fn device_free;
} qnn_api;

typedef struct op_config {
    uint32_t version;
    uint32_t reserved;
    const char *name, *package_name, *type_name;
    uint32_t param_count;
    uint32_t reserved2;
    const void *params;
    uint32_t input_count;
    uint32_t reserved3;
    const void *inputs;
    uint32_t output_count;
    uint32_t reserved4;
    const void *outputs;
} op_config;

_Static_assert(sizeof(op_config) == 80, "QNN op config ABI size");
_Static_assert(offsetof(op_config, inputs) == 56, "QNN op config ABI offset");

static void qnn_log(const char *fmt, int32_t level, uint64_t timestamp, va_list args) {
    (void)timestamp;
    fprintf(stderr, "QNN[%d] ", level);
    vfprintf(stderr, fmt, args);
    fputc('\n', stderr);
}

static void set_u32(unsigned char *p, size_t offset, uint32_t value) {
    memcpy(p + offset, &value, sizeof(value));
}

static void set_ptr(unsigned char *p, size_t offset, const void *value) {
    memcpy(p + offset, &value, sizeof(value));
}

static void init_tensor(unsigned char *tensor, const char *name, uint32_t type,
                        uint32_t *dims, uint16_t *data, uint32_t count) {
    memset(tensor, 0, 144);
    set_u32(tensor, 0, 1);          /* QNN_TENSOR_VERSION_1 */
    set_ptr(tensor, 16, name);
    set_u32(tensor, 24, type);      /* APP_WRITE=0, APP_READ=1 */
    set_u32(tensor, 32, 0x0416);    /* UFIXED_POINT_16 */
    set_u32(tensor, 40, 1);         /* quantization defined */
    set_u32(tensor, 44, 0);         /* per-tensor scale/offset */
    float scale = 1.0f;
    memcpy(tensor + 48, &scale, sizeof(scale));
    set_u32(tensor, 80, 4);
    set_ptr(tensor, 88, dims);
    set_u32(tensor, 96, 0);         /* QNN_TENSORMEMTYPE_RAW */
    set_ptr(tensor, 104, data);
    set_u32(tensor, 112, count * sizeof(*data));
}

static int run_known_add(qnn_api *api) {
    void *logger = NULL, *backend = NULL, *device = NULL, *context = NULL, *graph = NULL;
    int result = 2;
    uint64_t status;
    if (!api->backend_create || !api->backend_free || !api->device_create ||
        !api->device_free || !api->context_create || !api->context_free ||
        !api->graph_create || !api->graph_add_node || !api->graph_finalize ||
        !api->graph_execute || !api->tensor_create_graph) return 2;
    if (api->log_create && !api->log_create(qnn_log, 3, &logger))
        puts("{\"stage\":\"logger_create\",\"status\":0}");
    status = api->backend_create(logger, NULL, &backend);
    printf("{\"stage\":\"backend_create\",\"status\":%" PRIu64 "}\n", status);
    if (status || !backend) goto cleanup;
    status = api->device_create(logger, NULL, &device);
    printf("{\"stage\":\"device_create\",\"status\":%" PRIu64 "}\n", status);
    if (status || !device) goto cleanup;
    status = api->context_create(backend, device, NULL, &context);
    printf("{\"stage\":\"context_create\",\"status\":%" PRIu64 "}\n", status);
    if (status || !context) goto cleanup;
    status = api->graph_create(context, "known_add", NULL, &graph);
    printf("{\"stage\":\"graph_create\",\"status\":%" PRIu64 "}\n", status);
    if (status || !graph) goto cleanup;

    uint32_t dims[4] = {1, 1, 1, 64};
    uint16_t lhs[64], rhs[64], output[64];
    _Alignas(8) unsigned char tensors[3][144];
    for (uint32_t i = 0; i < 64; ++i) {
        lhs[i] = (uint16_t)i;
        rhs[i] = (uint16_t)(100 + i);
        output[i] = UINT16_MAX;
    }
    init_tensor(tensors[0], "lhs", 0, dims, lhs, 64);
    init_tensor(tensors[1], "rhs", 0, dims, rhs, 64);
    init_tensor(tensors[2], "sum", 1, dims, output, 64);
    for (uint32_t i = 0; i < 3; ++i) {
        status = api->tensor_create_graph(graph, tensors[i]);
        printf("{\"stage\":\"tensor_create\",\"index\":%u,\"status\":%" PRIu64 "}\n", i, status);
        if (status) goto cleanup;
    }
    _Alignas(8) unsigned char inputs[2][144];
    memcpy(inputs, tensors, sizeof(inputs));
    op_config op = {.version = 1, .name = "known_add_node", .package_name = "qti.aisw",
                    .type_name = "ElementWiseAdd", .input_count = 2,
                    .inputs = inputs, .output_count = 1, .outputs = tensors[2]};
    status = api->graph_add_node(graph, op);
    printf("{\"stage\":\"graph_add_node\",\"status\":%" PRIu64 "}\n", status);
    if (status) goto cleanup;
    status = api->graph_finalize(graph, NULL, NULL);
    printf("{\"stage\":\"graph_finalize\",\"status\":%" PRIu64 "}\n", status);
    if (status) goto cleanup;
    status = api->graph_execute(graph, inputs, 2, tensors[2], 1, NULL, NULL);
    printf("{\"stage\":\"graph_execute\",\"status\":%" PRIu64 "}\n", status);
    if (status) goto cleanup;
    uint32_t mismatches = 0;
    for (uint32_t i = 0; i < 64; ++i)
        mismatches += output[i] != (uint16_t)(100 + 2 * i);
    printf("{\"stage\":\"known_answer\",\"elements\":64,\"mismatches\":%u,\"first_actual\":%u,\"first_expected\":100}\n",
           mismatches, output[0]);
    if (!mismatches) result = 0;
cleanup:
    if (context) printf("{\"stage\":\"context_free\",\"status\":%" PRIu64 "}\n", api->context_free(context, NULL));
    if (device) printf("{\"stage\":\"device_free\",\"status\":%" PRIu64 "}\n", api->device_free(device));
    if (backend) printf("{\"stage\":\"backend_free\",\"status\":%" PRIu64 "}\n", api->backend_free(backend));
    if (logger && api->log_free) printf("{\"stage\":\"logger_free\",\"status\":%" PRIu64 "}\n", api->log_free(logger));
    return result;
}

int main(void) {
    void *library = dlopen("/vendor/lib64/libQnnHtp.so", RTLD_NOW | RTLD_LOCAL);
    if (!library) {
        fprintf(stderr, "QNN HTP load: %s\n", dlerror());
        return 2;
    }
    providers_fn get = (providers_fn)dlsym(library, "QnnInterface_getProviders");
    const void **providers = NULL;
    uint32_t count = 0;
    if (!get || get(&providers, &count) || count != 1 || !providers || !providers[0]) return 2;
    provider_prefix prefix;
    memcpy(&prefix, providers[0], sizeof(prefix));
    if (prefix.id != 6 || prefix.core.major != 2 || prefix.core.minor != 22) return 2;
    qnn_api api;
    memcpy(&api, (const unsigned char *)providers[0] + sizeof(prefix), sizeof(api));
    combined_version checked = {0};
    if (!api.backend_get_version || api.backend_get_version(&checked) ||
        memcmp(&checked, &prefix.core, sizeof(checked))) return 2;
    /* Retain HTP library until process exit; direct dlclose crashed in the
     * earlier VAE probe after otherwise successful QNN handle cleanup. */
    return run_known_add(&api);
}
