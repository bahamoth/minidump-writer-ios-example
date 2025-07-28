use minidump_handler::{init_crash_handler, write_minidump, HandlerConfig};
use std::ffi::{c_char, c_int, CStr};
use std::path::PathBuf;

/// Result type for FFI functions
#[repr(C)]
pub struct FFIResult {
    success: bool,
    error_message: *const c_char,
}

impl FFIResult {
    fn success() -> Self {
        Self {
            success: true,
            error_message: std::ptr::null(),
        }
    }

    fn error(msg: &'static str) -> Self {
        Self {
            success: false,
            error_message: msg.as_ptr() as *const c_char,
        }
    }

    fn error_owned(msg: String) -> Self {
        let c_str = std::ffi::CString::new(msg).unwrap();
        Self {
            success: false,
            error_message: c_str.into_raw(),
        }
    }
}

/// Write a minidump to the specified path
#[no_mangle]
pub extern "C" fn minidump_writer_ios_write_dump(path: *const c_char) -> FFIResult {
    if path.is_null() {
        return FFIResult::error("Path is null\0");
    }

    let path_str = unsafe {
        match CStr::from_ptr(path).to_str() {
            Ok(s) => s,
            Err(_) => return FFIResult::error("Invalid path encoding\0"),
        }
    };

    // Create parent directory if needed
    if let Some(parent) = std::path::Path::new(path_str).parent() {
        if !parent.exists() {
            if let Err(_) = std::fs::create_dir_all(parent) {
                return FFIResult::error("Failed to create output directory\0");
            }
        }
    }

    match write_minidump(std::path::Path::new(path_str)) {
        Ok(_) => FFIResult::success(),
        Err(e) => FFIResult::error_owned(format!("Failed to write minidump: {}\0", e)),
    }
}

/// Install crash handlers with the specified dump path
#[no_mangle]
pub extern "C" fn minidump_writer_ios_install_handlers(dump_path: *const c_char) -> FFIResult {
    if dump_path.is_null() {
        return FFIResult::error("Dump path is required\0");
    }

    let path_str = unsafe {
        match CStr::from_ptr(dump_path).to_str() {
            Ok(s) => s,
            Err(_) => return FFIResult::error("Invalid path encoding\0"),
        }
    };

    let config = HandlerConfig {
        dump_directory: PathBuf::from(path_str),
        filename_prefix: "ios_crash".to_string(),
        append_timestamp: true,
        pre_dump_callback: Some(|| {
            // This will be called before writing the dump
            // Could be used for logging, etc.
        }),
    };

    match init_crash_handler(config) {
        Ok(_) => FFIResult::success(),
        Err(e) => FFIResult::error_owned(format!("Failed to install handlers: {}\0", e)),
    }
}

/// Free an error message string
#[no_mangle]
pub extern "C" fn minidump_writer_ios_free_error_message(msg: *const c_char) {
    if !msg.is_null() {
        unsafe {
            let _ = std::ffi::CString::from_raw(msg as *mut c_char);
        }
    }
}

/// Check if the library is working properly
#[no_mangle]
pub extern "C" fn minidump_writer_ios_test() -> c_int {
    1 // Return 1 for success
}

/// Trigger various crash types for testing (only in debug builds)
#[cfg(debug_assertions)]
pub mod crash_test {
    use super::*;
    use minidump_handler::crash_triggers;

    #[no_mangle]
    pub extern "C" fn minidump_writer_ios_trigger_segfault() {
        crash_triggers::trigger_segfault();
    }

    #[no_mangle]
    pub extern "C" fn minidump_writer_ios_trigger_abort() {
        crash_triggers::trigger_abort();
    }

    #[no_mangle]
    pub extern "C" fn minidump_writer_ios_trigger_bus_error() {
        #[cfg(not(target_os = "windows"))]
        crash_triggers::trigger_bus_error();
    }

    #[no_mangle]
    pub extern "C" fn minidump_writer_ios_trigger_divide_by_zero() {
        crash_triggers::trigger_divide_by_zero();
    }

    #[no_mangle]
    pub extern "C" fn minidump_writer_ios_trigger_illegal_instruction() {
        crash_triggers::trigger_illegal_instruction();
    }

    #[no_mangle]
    pub extern "C" fn minidump_writer_ios_trigger_stack_overflow() {
        crash_triggers::trigger_stack_overflow();
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_write_dump() {
        let temp_path = "/tmp/test_dump.dmp\0";
        let result = minidump_writer_ios_write_dump(temp_path.as_ptr() as *const c_char);
        assert!(result.success);
        
        // Clean up
        let _ = std::fs::remove_file("/tmp/test_dump.dmp");
    }

    #[test]
    fn test_null_path() {
        let result = minidump_writer_ios_write_dump(std::ptr::null());
        assert!(!result.success);
    }
}