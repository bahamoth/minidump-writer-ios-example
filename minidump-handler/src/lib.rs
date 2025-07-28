use anyhow::{Context, Result};
use libc::{c_int, c_void, sigaction, siginfo_t, SIGABRT, SIGBUS, SIGFPE, SIGILL, SIGSEGV, SIGTRAP};
use once_cell::sync::OnceCell;
use std::path::{Path, PathBuf};
use std::sync::Mutex;

/// Global configuration for crash handling
static HANDLER_CONFIG: OnceCell<Mutex<HandlerConfig>> = OnceCell::new();

/// Configuration for the crash handler
#[derive(Clone)]
pub struct HandlerConfig {
    /// Directory where minidumps will be saved
    pub dump_directory: PathBuf,
    /// Prefix for minidump filenames
    pub filename_prefix: String,
    /// Whether to append timestamp to filenames
    pub append_timestamp: bool,
    /// Custom callback to run before writing minidump (optional)
    pub pre_dump_callback: Option<fn()>,
}

impl Default for HandlerConfig {
    fn default() -> Self {
        Self {
            dump_directory: PathBuf::from("./dumps"),
            filename_prefix: "crash".to_string(),
            append_timestamp: true,
            pre_dump_callback: None,
        }
    }
}

/// Signal information for crash context
#[derive(Debug, Clone)]
pub struct SignalInfo {
    pub signal: c_int,
    pub code: c_int,
    pub address: usize,
}

impl SignalInfo {
    fn from_siginfo(sig: c_int, info: *const siginfo_t) -> Self {
        unsafe {
            if info.is_null() {
                Self {
                    signal: sig,
                    code: 0,
                    address: 0,
                }
            } else {
                Self {
                    signal: sig,
                    code: (*info).si_code,
                    address: (*info).si_addr as usize,
                }
            }
        }
    }

    fn signal_name(&self) -> &'static str {
        match self.signal {
            SIGSEGV => "SIGSEGV",
            SIGBUS => "SIGBUS",
            SIGABRT => "SIGABRT",
            SIGFPE => "SIGFPE",
            SIGILL => "SIGILL",
            SIGTRAP => "SIGTRAP",
            _ => "UNKNOWN",
        }
    }
}

/// Initialize the crash handler with the given configuration
pub fn init_crash_handler(config: HandlerConfig) -> Result<()> {
    // Ensure dump directory exists
    std::fs::create_dir_all(&config.dump_directory)
        .with_context(|| format!("Failed to create dump directory: {:?}", config.dump_directory))?;

    // Store configuration
    HANDLER_CONFIG
        .set(Mutex::new(config))
        .map_err(|_| anyhow::anyhow!("Handler already initialized"))?;

    // Install signal handlers
    install_signal_handlers()?;

    Ok(())
}

/// Install signal handlers for common crash signals
fn install_signal_handlers() -> Result<()> {
    unsafe {
        let mut sa: sigaction = std::mem::zeroed();
        sa.sa_sigaction = signal_handler as usize;
        sa.sa_flags = libc::SA_SIGINFO;

        let signals = [SIGSEGV, SIGBUS, SIGABRT, SIGFPE, SIGILL, SIGTRAP];

        for &sig in &signals {
            if sigaction(sig, &sa, std::ptr::null_mut()) != 0 {
                return Err(anyhow::anyhow!(
                    "Failed to install handler for signal {}",
                    sig
                ));
            }
        }
    }

    Ok(())
}

/// Signal handler that generates minidump on crash
extern "C" fn signal_handler(sig: c_int, info: *mut siginfo_t, _context: *mut c_void) {
    // This runs in signal context - must be signal-safe!
    let signal_info = SignalInfo::from_siginfo(sig, info);
    
    // Try to get handler configuration
    if let Some(config_cell) = HANDLER_CONFIG.get() {
        if let Ok(config) = config_cell.try_lock() {
            // Run pre-dump callback if configured
            if let Some(callback) = config.pre_dump_callback {
                callback();
            }

            // Generate filename
            let filename = generate_filename(&config, &signal_info);
            let dump_path = config.dump_directory.join(filename);

            // Write minidump
            let _ = write_minidump_for_signal(&dump_path, &signal_info);
        }
    }

    // Re-raise the signal to trigger default behavior
    unsafe {
        libc::signal(sig, libc::SIG_DFL);
        libc::raise(sig);
    }
}

/// Generate a filename for the minidump
fn generate_filename(config: &HandlerConfig, signal_info: &SignalInfo) -> String {
    let mut filename = format!("{}_{}", config.filename_prefix, signal_info.signal_name().to_lowercase());
    
    if config.append_timestamp {
        let timestamp = std::time::SystemTime::now()
            .duration_since(std::time::UNIX_EPOCH)
            .unwrap_or_default()
            .as_secs();
        filename.push_str(&format!("_{}", timestamp));
    }
    
    filename.push_str(".dmp");
    filename
}

/// Platform-specific minidump writing
#[cfg(target_os = "macos")]
fn write_minidump_for_signal(path: &Path, _signal_info: &SignalInfo) -> Result<()> {
    use minidump_writer::minidump_writer::MinidumpWriter;
    
    // Create the writer with current task and thread
    let mut writer = MinidumpWriter::new(None, None);
    
    // Write the minidump
    writer.dump(&mut std::fs::File::create(path)?)
        .map_err(|e| anyhow::anyhow!("Failed to write minidump: {}", e))?;
    
    Ok(())
}

#[cfg(target_os = "ios")]
fn write_minidump_for_signal(path: &Path, signal_info: &SignalInfo) -> Result<()> {
    use minidump_writer::apple::ios::{MinidumpWriter, IosCrashContext, IosExceptionInfo};
    
    // Get current thread state
    let thread = unsafe { mach2::mach_init::mach_thread_self() };
    let task = unsafe { mach2::traps::mach_task_self() };
    
    // Create iOS crash context
    let crash_context = IosCrashContext {
        task,
        thread,
        handler_thread: thread, // Same as thread in signal handler
        exception: Some(IosExceptionInfo {
            kind: signal_info.signal as u32,
            code: signal_info.code as u64,
            subcode: Some(signal_info.address as u64),
        }),
        thread_state: Default::default(), // Will be filled by writer
    };
    
    let mut writer = MinidumpWriter::new();
    writer.set_crash_context(crash_context);
    
    // Write the minidump
    writer.dump(&mut std::fs::File::create(path)?)
        .map_err(|e| anyhow::anyhow!("Failed to write minidump: {}", e))?;
    
    Ok(())
}

#[cfg(target_os = "linux")]
fn write_minidump_for_signal(path: &Path, signal_info: &SignalInfo) -> Result<()> {
    use minidump_writer::linux::minidump_writer::MinidumpWriter;
    use minidump_writer::linux::crash_context::CrashContext;
    
    // Create crash context
    let crash_context = CrashContext {
        siginfo: std::ptr::null(),
        pid: std::process::id() as i32,
        tid: unsafe { libc::syscall(libc::SYS_gettid) } as i32,
        context: std::ptr::null_mut(),
        float_state: std::ptr::null_mut(),
    };
    
    let mut writer = MinidumpWriter::with_crash_context(crash_context);
    writer.dump_and_write_to_disk(path)
        .map_err(|e| anyhow::anyhow!("Failed to write minidump: {}", e))?;
    
    Ok(())
}

/// Manually write a minidump for the current process (no crash)
pub fn write_minidump(path: &Path) -> Result<()> {
    #[cfg(target_os = "macos")]
    {
        use minidump_writer::minidump_writer::MinidumpWriter;
        
        let mut writer = MinidumpWriter::new(None, None);
        
        writer.dump(&mut std::fs::File::create(path)?)
            .map_err(|e| anyhow::anyhow!("Failed to write minidump: {}", e))?;
    }
    
    #[cfg(target_os = "ios")]
    {
        use minidump_writer::apple::ios::MinidumpWriter;
        
        let mut writer = MinidumpWriter::new();
        writer.dump(&mut std::fs::File::create(path)?)
            .map_err(|e| anyhow::anyhow!("Failed to write minidump: {}", e))?;
    }
    
    #[cfg(target_os = "linux")]
    {
        use minidump_writer::linux::minidump_writer::MinidumpWriter;
        
        let writer = MinidumpWriter::new(std::process::id() as i32);
        writer.dump_and_write_to_disk(path)
            .map_err(|e| anyhow::anyhow!("Failed to write minidump: {}", e))?;
    }
    
    Ok(())
}

/// Trigger various types of crashes for testing
pub mod crash_triggers {
    use std::ptr;

    /// Trigger a segmentation fault
    pub fn trigger_segfault() {
        unsafe {
            let null_ptr: *mut i32 = ptr::null_mut();
            *null_ptr = 42;
        }
    }

    /// Trigger a bus error
    #[cfg(not(target_os = "windows"))]
    pub fn trigger_bus_error() {
        unsafe {
            let misaligned = 0x1001 as *const i64;
            let _value = ptr::read_volatile(misaligned);
        }
    }

    /// Trigger an abort
    pub fn trigger_abort() {
        std::process::abort();
    }

    /// Trigger a divide by zero
    pub fn trigger_divide_by_zero() {
        let zero = 0;
        let result = std::panic::catch_unwind(|| {
            42 / zero
        });
        if result.is_err() {
            // Force a SIGFPE by using inline assembly
            #[cfg(target_arch = "x86_64")]
            unsafe {
                std::arch::asm!(
                    "xor %eax, %eax",
                    "xor %edx, %edx",
                    "div %eax"
                );
            }
            #[cfg(target_arch = "aarch64")]
            unsafe {
                std::arch::asm!(
                    "mov x0, #42",
                    "mov x1, #0",
                    "sdiv x0, x0, x1"
                );
            }
        }
    }

    /// Trigger an illegal instruction
    #[cfg(target_arch = "x86_64")]
    pub fn trigger_illegal_instruction() {
        unsafe {
            std::arch::asm!("ud2");
        }
    }
    
    #[cfg(target_arch = "aarch64")]
    pub fn trigger_illegal_instruction() {
        unsafe {
            std::arch::asm!(".word 0x00000000");
        }
    }

    /// Trigger a stack overflow
    pub fn trigger_stack_overflow() {
        fn recurse(n: u64) -> u64 {
            let arr = [0u8; 8192]; // Large stack allocation
            if n > 0 {
                recurse(n + 1) + arr[0] as u64
            } else {
                n
            }
        }
        recurse(0);
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::fs;
    use tempfile::TempDir;

    #[test]
    fn test_init_handler() {
        let temp_dir = TempDir::new().unwrap();
        let config = HandlerConfig {
            dump_directory: temp_dir.path().to_path_buf(),
            ..Default::default()
        };
        
        assert!(init_crash_handler(config).is_ok());
    }

    #[test]
    fn test_manual_minidump() {
        let temp_dir = TempDir::new().unwrap();
        let dump_path = temp_dir.path().join("test.dmp");
        
        assert!(write_minidump(&dump_path).is_ok());
        assert!(dump_path.exists());
        
        // Verify file is not empty
        let metadata = fs::metadata(&dump_path).unwrap();
        assert!(metadata.len() > 0);
    }
}