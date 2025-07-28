use anyhow::{Context, Result};
use clap::{Parser, Subcommand};
use colored::*;
use minidump_handler::{crash_triggers, init_crash_handler, write_minidump, HandlerConfig};
use std::path::PathBuf;

#[derive(Parser)]
#[command(name = "minidump-gen")]
#[command(about = "Generate minidumps for testing crash scenarios", long_about = None)]
struct Cli {
    /// Output directory for minidumps
    #[arg(short, long, default_value = "./dumps")]
    output: PathBuf,

    /// Filename prefix for generated dumps
    #[arg(short, long, default_value = "crash")]
    prefix: String,

    /// Install crash handler before executing command
    #[arg(short = 'H', long)]
    install_handler: bool,

    #[command(subcommand)]
    command: Commands,
}

#[derive(Subcommand)]
enum Commands {
    /// Generate a minidump of the current process without crashing
    Dump {
        /// Output filename (without .dmp extension)
        #[arg(short, long, default_value = "manual_dump")]
        name: String,
    },

    /// Trigger a specific type of crash
    Crash {
        /// Type of crash to trigger
        #[command(subcommand)]
        crash_type: CrashType,
    },

    /// List available crash types
    List,

    /// Run in interactive mode (install handler and wait)
    Interactive {
        /// Timeout in seconds (0 = infinite)
        #[arg(short, long, default_value = "0")]
        timeout: u64,
    },
}

#[derive(Subcommand, Clone)]
enum CrashType {
    /// Segmentation fault (null pointer dereference)
    Segfault,
    /// Bus error (misaligned memory access)
    #[cfg(not(target_os = "windows"))]
    BusError,
    /// Abort signal
    Abort,
    /// Division by zero
    DivideByZero,
    /// Illegal instruction
    IllegalInstruction,
    /// Stack overflow
    StackOverflow,
}

impl CrashType {
    fn description(&self) -> &'static str {
        match self {
            Self::Segfault => "Null pointer dereference causing SIGSEGV",
            #[cfg(not(target_os = "windows"))]
            Self::BusError => "Misaligned memory access causing SIGBUS",
            Self::Abort => "Process abort causing SIGABRT",
            Self::DivideByZero => "Integer division by zero causing SIGFPE",
            Self::IllegalInstruction => "Invalid CPU instruction causing SIGILL",
            Self::StackOverflow => "Recursive function causing stack exhaustion",
        }
    }

    fn trigger(&self) {
        match self {
            Self::Segfault => crash_triggers::trigger_segfault(),
            #[cfg(not(target_os = "windows"))]
            Self::BusError => crash_triggers::trigger_bus_error(),
            Self::Abort => crash_triggers::trigger_abort(),
            Self::DivideByZero => crash_triggers::trigger_divide_by_zero(),
            Self::IllegalInstruction => crash_triggers::trigger_illegal_instruction(),
            Self::StackOverflow => crash_triggers::trigger_stack_overflow(),
        }
    }
}

fn main() -> Result<()> {
    let cli = Cli::parse();

    // Create output directory
    std::fs::create_dir_all(&cli.output)
        .with_context(|| format!("Failed to create output directory: {:?}", cli.output))?;

    // Install crash handler if requested
    if cli.install_handler {
        println!("{}", "Installing crash handler...".green());
        
        let config = HandlerConfig {
            dump_directory: cli.output.clone(),
            filename_prefix: cli.prefix.clone(),
            append_timestamp: true,
            pre_dump_callback: Some(|| {
                eprintln!("{}", "Crash detected! Writing minidump...".red().bold());
            }),
        };
        
        init_crash_handler(config)?;
        println!("{}", "✓ Crash handler installed".green());
    }

    match cli.command {
        Commands::Dump { name } => {
            println!("{}", "Generating minidump...".blue());
            let dump_path = cli.output.join(format!("{}.dmp", name));
            
            write_minidump(&dump_path)
                .with_context(|| "Failed to write minidump")?;
            
            println!("{} {}", "✓ Minidump written to:".green(), dump_path.display());
        }

        Commands::Crash { crash_type } => {
            if !cli.install_handler {
                println!("{}", "Warning: No crash handler installed. Use -H to capture minidump.".yellow());
            }
            
            println!("{} {}", "Triggering crash:".red(), crash_type.description());
            println!("{}", "This will terminate the process!".red().bold());
            
            // Small delay to ensure output is flushed
            std::thread::sleep(std::time::Duration::from_millis(100));
            
            crash_type.trigger();
        }

        Commands::List => {
            println!("{}", "Available crash types:".bold());
            println!("  {} - {}", "segfault".cyan(), CrashType::Segfault.description());
            #[cfg(not(target_os = "windows"))]
            println!("  {} - {}", "bus-error".cyan(), CrashType::BusError.description());
            println!("  {} - {}", "abort".cyan(), CrashType::Abort.description());
            println!("  {} - {}", "divide-by-zero".cyan(), CrashType::DivideByZero.description());
            println!("  {} - {}", "illegal-instruction".cyan(), CrashType::IllegalInstruction.description());
            println!("  {} - {}", "stack-overflow".cyan(), CrashType::StackOverflow.description());
            
            println!("\n{}", "Example usage:".bold());
            println!("  minidump-gen -H crash segfault");
            println!("  minidump-gen dump --name my_dump");
        }

        Commands::Interactive { timeout } => {
            if !cli.install_handler {
                let config = HandlerConfig {
                    dump_directory: cli.output.clone(),
                    filename_prefix: cli.prefix.clone(),
                    append_timestamp: true,
                    pre_dump_callback: Some(|| {
                        eprintln!("{}", "Crash detected! Writing minidump...".red().bold());
                    }),
                };
                
                init_crash_handler(config)?;
            }
            
            println!("{}", "Running in interactive mode...".green());
            println!("Crash handler is active. Process will capture minidumps on crash.");
            println!("Output directory: {}", cli.output.display());
            
            if timeout > 0 {
                println!("Timeout: {} seconds", timeout);
                std::thread::sleep(std::time::Duration::from_secs(timeout));
                println!("Timeout reached, exiting...");
            } else {
                println!("Press Ctrl+C to exit...");
                std::thread::park();
            }
        }
    }

    Ok(())
}