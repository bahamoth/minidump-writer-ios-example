use flutter_rust_bridge::frb;
use std::path::Path;

#[derive(Debug)]
pub struct MinidumpResult {
    pub success: bool,
    pub error: Option<String>,
}

#[derive(Debug)]
pub enum CrashType {
    Segfault,
    Abort,
    BusError,
    DivideByZero,
    IllegalInstruction,
    StackOverflow,
}

pub struct MinidumpApi {}

impl MinidumpApi {
    #[frb(sync)]
    pub fn new() -> Self {
        flutter_rust_bridge::setup_default_user_utils();
        Self {}
    }

    pub fn write_dump(&self, path: String) -> Result<MinidumpResult, anyhow::Error> {
        match minidump_handler::write_minidump(Path::new(&path)) {
            Ok(_) => Ok(MinidumpResult {
                success: true,
                error: None,
            }),
            Err(e) => Ok(MinidumpResult {
                success: false,
                error: Some(e.to_string()),
            }),
        }
    }

    pub fn install_handlers(&self, dump_path: String) -> Result<MinidumpResult, anyhow::Error> {
        match minidump_handler::install_handlers(&dump_path) {
            Ok(_) => Ok(MinidumpResult {
                success: true,
                error: None,
            }),
            Err(e) => Ok(MinidumpResult {
                success: false,
                error: Some(e.to_string()),
            }),
        }
    }

    #[frb(sync)]
    pub fn test(&self) -> bool {
        true
    }

    #[cfg(debug_assertions)]
    pub fn trigger_crash(&self, crash_type: CrashType) -> Result<(), anyhow::Error> {
        match crash_type {
            CrashType::Segfault => minidump_handler::trigger_segfault(),
            CrashType::Abort => minidump_handler::trigger_abort(),
            CrashType::BusError => minidump_handler::trigger_bus_error(),
            CrashType::DivideByZero => minidump_handler::trigger_divide_by_zero(),
            CrashType::IllegalInstruction => minidump_handler::trigger_illegal_instruction(),
            CrashType::StackOverflow => minidump_handler::trigger_stack_overflow(),
        }
        Ok(())
    }

    #[cfg(not(debug_assertions))]
    pub fn trigger_crash(&self, _crash_type: CrashType) -> Result<(), anyhow::Error> {
        Err(anyhow::anyhow!("Crash triggers are only available in debug builds"))
    }

    #[frb(sync)]
    pub fn has_crash_triggers(&self) -> bool {
        cfg!(debug_assertions)
    }
}