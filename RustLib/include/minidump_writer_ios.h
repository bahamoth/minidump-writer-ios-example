#include <stdarg.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdlib.h>

/**
 * Result type for FFI functions
 */
typedef struct FFIResult {
  bool success;
  const char *error_message;
} FFIResult;

/**
 * Write a minidump to the specified path
 */
struct FFIResult minidump_writer_ios_write_dump(const char *path);

/**
 * Install crash handlers with the specified dump path
 */
struct FFIResult minidump_writer_ios_install_handlers(const char *dump_path);

/**
 * Free an error message string
 */
void minidump_writer_ios_free_error_message(const char *msg);

/**
 * Check if the library is working properly
 */
int minidump_writer_ios_test(void);

void minidump_writer_ios_trigger_segfault(void);

void minidump_writer_ios_trigger_abort(void);

void minidump_writer_ios_trigger_bus_error(void);

void minidump_writer_ios_trigger_divide_by_zero(void);

void minidump_writer_ios_trigger_illegal_instruction(void);

void minidump_writer_ios_trigger_stack_overflow(void);
