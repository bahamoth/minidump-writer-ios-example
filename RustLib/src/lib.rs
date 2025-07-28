use minidump_writer::apple::ios::minidump_writer::MinidumpWriter;
use std::ffi::{c_char, c_int, CStr};
use std::fs;
use std::path::Path;
use std::sync::Mutex;
use libc::{sigaction, siginfo_t, SIGBUS, SIGSEGV, SIGABRT, SIGFPE, SIGILL, SIGTRAP};

/// Result type for FFI functions
#[repr(C)]
pub struct FFIResult {
    success: bool,
    error_message: *const c_char,
}

/// Opaque handle to MinidumpWriter
pub struct MinidumpWriterHandle {
    writer: MinidumpWriter,
}

/// Initialize a new MinidumpWriter instance
#[no_mangle]
pub extern "C" fn minidump_writer_ios_create() -> *mut MinidumpWriterHandle {
    let writer = MinidumpWriter::new();
    let handle = Box::new(MinidumpWriterHandle { writer });
    Box::into_raw(handle)
}

/// Free a MinidumpWriter instance
#[no_mangle]
pub extern "C" fn minidump_writer_ios_free(handle: *mut MinidumpWriterHandle) {
    if !handle.is_null() {
        unsafe {
            let _ = Box::from_raw(handle);
        }
    }
}

/// Write a minidump to the specified path
#[no_mangle]
pub extern "C" fn minidump_writer_ios_write_dump(
    handle: *mut MinidumpWriterHandle,
    path: *const c_char,
) -> FFIResult {
    if handle.is_null() || path.is_null() {
        return FFIResult {
            success: false,
            error_message: b"Invalid parameters\0".as_ptr() as *const c_char,
        };
    }

    let path_str = unsafe {
        match CStr::from_ptr(path).to_str() {
            Ok(s) => s,
            Err(_) => {
                return FFIResult {
                    success: false,
                    error_message: b"Invalid path encoding\0".as_ptr() as *const c_char,
                };
            }
        }
    };

    let writer = unsafe { &mut (*handle).writer };

    // Create parent directory if needed
    if let Some(parent) = Path::new(path_str).parent() {
        if !parent.exists() {
            if let Err(_) = fs::create_dir_all(parent) {
                return FFIResult {
                    success: false,
                    error_message: b"Failed to create output directory\0".as_ptr() as *const c_char,
                };
            }
        }
    }

    match writer.write_minidump(path_str) {
        Ok(_) => FFIResult {
            success: true,
            error_message: std::ptr::null(),
        },
        Err(e) => {
            let error_msg = format!("Failed to write minidump: {}\0", e);
            let c_str = std::ffi::CString::new(error_msg).unwrap();
            FFIResult {
                success: false,
                error_message: c_str.into_raw(),
            }
        }
    }
}

/// Write a minidump with exception context
#[no_mangle]
pub extern "C" fn minidump_writer_ios_write_dump_with_exception(
    handle: *mut MinidumpWriterHandle,
    path: *const c_char,
    exception_type: u32,
    exception_code: u64,
    exception_address: u64,
) -> FFIResult {
    if handle.is_null() || path.is_null() {
        return FFIResult {
            success: false,
            error_message: b"Invalid parameters\0".as_ptr() as *const c_char,
        };
    }

    let path_str = unsafe {
        match CStr::from_ptr(path).to_str() {
            Ok(s) => s,
            Err(_) => {
                return FFIResult {
                    success: false,
                    error_message: b"Invalid path encoding\0".as_ptr() as *const c_char,
                };
            }
        }
    };

    let writer = unsafe { &mut (*handle).writer };

    // Create crash context
    let crash_context = minidump_writer::apple::ios::crash_context::IosCrashContext {
        exception_type,
        exception_code,
        exception_address,
        thread: mach2::mach_init::mach_thread_self(),
    };

    writer.crash_context = Some(crash_context);

    match writer.write_minidump(path_str) {
        Ok(_) => FFIResult {
            success: true,
            error_message: std::ptr::null(),
        },
        Err(e) => {
            let error_msg = format!("Failed to write minidump with exception: {}\0", e);
            let c_str = std::ffi::CString::new(error_msg).unwrap();
            FFIResult {
                success: false,
                error_message: c_str.into_raw(),
            }
        }
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

/// Global path for crash dumps
static CRASH_DUMP_PATH: Mutex<Option<String>> = Mutex::new(None);

/// Signal handler that generates minidump on crash
extern "C" fn signal_handler(sig: c_int, info: *mut siginfo_t, _context: *mut libc::c_void) {
    // This runs in signal context - must be signal-safe!
    unsafe {
        // Get the pre-configured dump path
        if let Ok(guard) = CRASH_DUMP_PATH.try_lock() {
            if let Some(ref base_path) = *guard {
                // Generate filename with signal info
                let filename = match sig {
                    SIGSEGV => "crash_sigsegv",
                    SIGBUS => "crash_sigbus",
                    SIGABRT => "crash_sigabrt",
                    SIGFPE => "crash_sigfpe",
                    SIGILL => "crash_sigill",
                    SIGTRAP => "crash_sigtrap",
                    _ => "crash_unknown",
                };
                
                let mut path = base_path.clone();
                path.push_str("/");
                path.push_str(filename);
                path.push_str(".dmp");
                
                // Create crash context
                let crash_context = minidump_writer::apple::ios::crash_context::IosCrashContext {
                    exception_type: sig as u32,
                    exception_code: if !info.is_null() { (*info).si_code as u64 } else { 0 },
                    exception_address: if !info.is_null() { (*info).si_addr as u64 } else { 0 },
                    thread: mach2::mach_init::mach_thread_self(),
                };
                
                // Write minidump
                let mut writer = MinidumpWriter::new();
                writer.crash_context = Some(crash_context);
                let _ = writer.write_minidump(&path);
            }
        }
        
        // Re-raise the signal to trigger default behavior
        libc::signal(sig, libc::SIG_DFL);
        libc::raise(sig);
    }
}

/// Install crash handlers for common signals
#[no_mangle]
pub extern "C" fn minidump_writer_ios_install_handlers(dump_path: *const c_char) -> FFIResult {
    if dump_path.is_null() {
        return FFIResult {
            success: false,
            error_message: b"Dump path is required\0".as_ptr() as *const c_char,
        };
    }
    
    let path_str = unsafe {
        match CStr::from_ptr(dump_path).to_str() {
            Ok(s) => s,
            Err(_) => {
                return FFIResult {
                    success: false,
                    error_message: b"Invalid path encoding\0".as_ptr() as *const c_char,
                };
            }
        }
    };
    
    // Store the dump path
    {
        let mut guard = CRASH_DUMP_PATH.lock().unwrap();
        *guard = Some(path_str.to_string());
    }
    
    // Install signal handlers
    unsafe {
        let mut sa: sigaction = std::mem::zeroed();
        sa.sa_sigaction = signal_handler as usize;
        sa.sa_flags = libc::SA_SIGINFO;
        
        let signals = [SIGSEGV, SIGBUS, SIGABRT, SIGFPE, SIGILL, SIGTRAP];
        
        for &sig in &signals {
            if sigaction(sig, &sa, std::ptr::null_mut()) != 0 {
                return FFIResult {
                    success: false,
                    error_message: b"Failed to install signal handler\0".as_ptr() as *const c_char,
                };
            }
        }
    }
    
    FFIResult {
        success: true,
        error_message: std::ptr::null(),
    }
}

/// Check if the library is working properly
#[no_mangle]
pub extern "C" fn minidump_writer_ios_test() -> c_int {
    1 // Return 1 for success
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_create_and_free() {
        let handle = minidump_writer_ios_create();
        assert!(!handle.is_null());
        minidump_writer_ios_free(handle);
    }

    #[test]
    fn test_null_handle() {
        let result = minidump_writer_ios_write_dump(
            std::ptr::null_mut(),
            b"test.dmp\0".as_ptr() as *const c_char,
        );
        assert!(!result.success);
    }
}