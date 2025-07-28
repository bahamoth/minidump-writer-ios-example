# iOS Example App Project Context

## Project Goal
This project implements T-012 from @deps/minidump-writer/TASKS.md: Create an iOS example app that serves as a test harness for minidump-writer development on iOS.

### Key Objectives
- **Primary**: Verify minidump-writer works correctly on iOS simulator and physical devices
- **Core**: Test all minidump context types are properly captured:
  - Thread list with full thread states
  - System information (device, OS, architecture)
  - Memory regions and contents
  - Exception handling for various signals/exceptions
  - Crash context preservation
- **Critical**: Ensure minidumps can be:
  - Successfully written to iOS filesystem
  - Retrieved and analyzed post-crash
  - Validated for completeness and accuracy

## Technical Decisions

### 1. Integration Approach
- **Current**: Direct Swift FFI (subject to change based on effectiveness)
- **Priority**: Whatever method best validates minidump-writer functionality
- **Flexibility**: Open to alternative approaches if they better serve testing needs

### 2. Platform Support
- **Target**: ARM64 only (aarch64-apple-ios, aarch64-apple-ios-sim)
- **No x86**: No x86_64 simulator support needed
- **Rationale**: Modern iOS development reality

### 3. Testing Focus
- **Not a demo**: This is a test harness, not a showcase
- **Comprehensive**: Must exercise all minidump-writer capabilities
- **Validation**: Built-in verification of dump contents

## Implementation Plan

### Phase 1: Project Setup ✓
- [x] Add minidump-writer as git submodule
- [x] Create project documentation (this file)

### Phase 2: Rust FFI Library
- [ ] Create RustLib directory with Cargo project
- [ ] Implement C-compatible wrapper functions:
  - `minidump_writer_ios_init()` - Initialize the writer
  - `minidump_writer_ios_write_dump()` - Generate minidump
  - `minidump_writer_ios_set_crash_handler()` - Install crash handler
- [ ] Configure iOS targets (aarch64-apple-ios, x86_64-apple-ios-sim)
- [ ] Create build script for universal library

### Phase 3: iOS App Structure
- [ ] Create Xcode project (MinidumpWriterExample.xcodeproj)
- [ ] Set up SwiftUI-based interface
- [ ] Configure module map or bridging header for FFI
- [ ] Implement Swift wrapper for Rust functions

### Phase 4: Core Testing Features
- [ ] Test scenarios for different crash types:
  - SIGSEGV (null pointer dereference)
  - SIGBUS (bus error)
  - SIGABRT (assertion failure)
  - EXC_BAD_ACCESS (memory access violation)
  - Stack overflow
  - Divide by zero
- [ ] Minidump validation features:
  - Verify thread count and states
  - Check system info completeness
  - Validate memory regions captured
  - Ensure exception context preserved
- [ ] File management:
  - List generated minidumps
  - Export dumps for analysis
  - Clear old dumps

### Phase 5: Documentation
- [ ] README with build instructions
- [ ] Code comments explaining FFI patterns
- [ ] Usage examples

## Project Structure

```
minidump-writer-ios-example/
├── CLAUDE.md (this file)
├── README.md
├── deps/
│   └── minidump-writer/ (submodule)
├── RustLib/
│   ├── Cargo.toml
│   ├── src/
│   │   └── lib.rs (FFI exports)
│   └── build_ios.sh
├── MinidumpWriterExample/
│   ├── MinidumpWriterExample.xcodeproj/
│   ├── MinidumpWriterExample/
│   │   ├── App/
│   │   │   ├── MinidumpWriterExampleApp.swift
│   │   │   └── AppDelegate.swift
│   │   ├── Views/
│   │   │   ├── ContentView.swift
│   │   │   └── MinidumpListView.swift
│   │   ├── RustBridge/
│   │   │   ├── MinidumpWriter.swift (Swift wrapper)
│   │   │   └── module.modulemap
│   │   └── Resources/
│   │       ├── Info.plist
│   │       └── Assets.xcassets/
│   └── MinidumpWriterExampleTests/
└── .gitignore
```

## Build Requirements

- macOS with Xcode 14.0+
- Rust toolchain with iOS ARM64 targets:
  - `rustup target add aarch64-apple-ios`
  - `rustup target add aarch64-apple-ios-sim`
- iOS 15.0+ deployment target
- Swift 5.5+
- Physical iOS device or M1+ Mac for testing (ARM64 only)

## Progress Tracking

### Current Status
- Project initialized with minidump-writer submodule
- Basic project structure planned
- Working on Rust FFI library implementation

### Next Steps
1. Create RustLib directory and Cargo project
2. Implement FFI wrapper functions
3. Set up iOS build configuration

## Development Notes

### FFI Pattern
```rust
// Rust side
#[no_mangle]
pub extern "C" fn minidump_writer_ios_init() -> i32 {
    // Implementation
}
```

```swift
// Swift side
@_silgen_name("minidump_writer_ios_init")
func minidumpWriterInit() -> Int32

// Or via module map
import MinidumpWriterFFI
```

### Build Commands
```bash
# Build Rust library for iOS
cd RustLib
./build_ios.sh

# Open Xcode project
open MinidumpWriterExample/MinidumpWriterExample.xcodeproj
```

## Known Constraints

1. **No macOS Development Machine**: Initial development without access to macOS/Xcode
   - **CRITICAL**: Code quality must be exceptional as review/testing is deferred
   - All iOS APIs and patterns must be correctly implemented first time
   - No room for "hack and see" development approach

2. **Testing Limitations**: Cannot validate functionality until macOS access
   - Must rely on documentation and best practices
   - Code must be self-evidently correct

3. **Quality Requirements**: 
   - This is a test harness for a critical safety component
   - Incorrect implementation will be discovered and must be avoided
   - Better to implement less but correctly than more with errors

## References

- minidump-writer TASKS.md: T-012
- minidump-writer iOS implementation: deps/minidump-writer/src/ios/
- Apple FFI Documentation: https://developer.apple.com/documentation/swift/imported_c_and_objective-c_apis