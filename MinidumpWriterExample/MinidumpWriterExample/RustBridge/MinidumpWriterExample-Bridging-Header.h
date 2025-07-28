//
//  MinidumpWriterExample-Bridging-Header.h
//  MinidumpWriterExample
//
//  Bridging header for Rust FFI functions
//

#ifndef MinidumpWriterExample_Bridging_Header_h
#define MinidumpWriterExample_Bridging_Header_h

#include <stdbool.h>
#include <stdint.h>

// FFI Result structure
typedef struct {
    bool success;
    const char* error_message;
} FFIResult;

// Opaque handle to MinidumpWriter
typedef struct MinidumpWriterHandle MinidumpWriterHandle;

// FFI function declarations
MinidumpWriterHandle* minidump_writer_ios_create(void);
void minidump_writer_ios_free(MinidumpWriterHandle* handle);
FFIResult minidump_writer_ios_write_dump(MinidumpWriterHandle* handle, const char* path);
FFIResult minidump_writer_ios_write_dump_with_exception(
    MinidumpWriterHandle* handle,
    const char* path,
    uint32_t exception_type,
    uint64_t exception_code,
    uint64_t exception_address
);
void minidump_writer_ios_free_error_message(const char* msg);
FFIResult minidump_writer_ios_install_handlers(const char* dump_path);
int minidump_writer_ios_test(void);

#endif /* MinidumpWriterExample_Bridging_Header_h */