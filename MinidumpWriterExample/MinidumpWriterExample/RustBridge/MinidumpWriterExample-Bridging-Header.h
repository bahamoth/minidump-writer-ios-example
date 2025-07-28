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

// Core FFI function declarations
FFIResult minidump_writer_ios_write_dump(const char* path);
FFIResult minidump_writer_ios_install_handlers(const char* dump_path);
void minidump_writer_ios_free_error_message(const char* msg);
int minidump_writer_ios_test(void);

// Crash test functions (only available in debug builds)
#ifdef DEBUG
void minidump_writer_ios_trigger_segfault(void);
void minidump_writer_ios_trigger_abort(void);
void minidump_writer_ios_trigger_bus_error(void);
void minidump_writer_ios_trigger_divide_by_zero(void);
void minidump_writer_ios_trigger_illegal_instruction(void);
void minidump_writer_ios_trigger_stack_overflow(void);
#endif

#endif /* MinidumpWriterExample_Bridging_Header_h */