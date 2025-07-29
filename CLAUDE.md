# MinidumpWriter Flutter Test App

## Project Goal
Cross-platform test harness for minidump-writer library, extending the original iOS-only scope (T-012 from @deps/minidump-writer/TASKS.md) to support comprehensive testing across all major platforms.

### Key Objectives
- **Primary**: Verify minidump-writer works correctly across iOS, Android, Linux, Windows, and macOS
- **Core**: Test all minidump context types are properly captured on each platform:
  - Thread list with full thread states
  - System information (device, OS, architecture)
  - Memory regions and contents
  - Exception handling for various signals/exceptions
  - Crash context preservation
- **Critical**: Ensure minidumps can be:
  - Successfully written to platform-specific filesystems
  - Retrieved and analyzed post-crash
  - Validated for completeness and accuracy across platforms

## Technical Stack

### 1. Flutter + Dart FFI
- **UI Framework**: Flutter for cross-platform UI
- **FFI Integration**: dart:ffi for direct Rust library binding
- **Platforms**: iOS, Android, Linux, Windows, macOS

### 2. Rust Components
- **minidump-handler**: Core crash handling library with platform-specific implementations
- **minidump-gen-cli**: Command-line testing tool for rapid iteration

### 3. Architecture
```
Flutter App (Dart)
    ↓ dart:ffi
minidump-handler (Rust)
    ↓ platform APIs
OS Crash Handlers
```

## Project Structure

```
minidump-writer-flutter-test/
├── CLAUDE.md (this file)
├── README.md
├── deps/
│   └── minidump-writer/ (submodule)
├── rust/
│   ├── Cargo.toml (workspace)
│   ├── minidump-handler/
│   │   ├── Cargo.toml
│   │   └── src/
│   │       └── lib.rs
│   └── minidump-gen-cli/
│       ├── Cargo.toml
│       └── src/
│           └── main.rs
├── lib/
│   ├── main.dart
│   ├── ffi/
│   │   └── minidump_bindings.dart
│   ├── screens/
│   │   ├── home_screen.dart
│   │   ├── crash_test_screen.dart
│   │   └── minidump_list_screen.dart
│   └── services/
│       ├── minidump_service.dart
│       └── platform_service.dart
├── ios/
├── android/
├── linux/
├── windows/
├── macos/
├── pubspec.yaml
└── test/
```

## Implementation Status

### Phase 1: Project Migration ✓
- [x] Created Rust workspace structure
- [x] Moved minidump-handler to rust/
- [x] Renamed and moved minidump-gen to rust/minidump-gen-cli
- [x] Created Flutter project with all platforms

### Phase 2: FFI Integration (In Progress)
- [ ] Implement dart:ffi bindings for minidump-handler
- [ ] Platform-specific library loading
- [ ] Build scripts for each platform

### Phase 3: UI Implementation
- [ ] Home screen with platform info
- [ ] Crash test scenarios screen
- [ ] Minidump viewer/exporter screen
- [ ] Settings for handler configuration

### Phase 4: Platform-Specific Testing
- [ ] iOS: Test on simulator and physical devices
- [ ] Android: Test on emulator and physical devices
- [ ] Linux: Test native builds
- [ ] Windows: Test native builds
- [ ] macOS: Test native builds

### Phase 5: Validation & Documentation
- [ ] Automated minidump validation
- [ ] Platform-specific build guides
- [ ] Usage documentation

## Build Requirements

### General
- Flutter SDK 3.0+
- Rust toolchain (stable)
- Platform-specific tools (see below)

### iOS
- macOS with Xcode 14.0+
- `rustup target add aarch64-apple-ios aarch64-apple-ios-sim`

### Android
- Android Studio / Android SDK
- NDK for native builds
- `rustup target add aarch64-linux-android armv7-linux-androideabi`

### Linux
- Standard build tools (gcc, cmake)
- GTK development headers

### Windows
- Visual Studio 2019+ with C++ tools
- Windows SDK

### macOS
- Xcode command line tools
- `rustup target add aarch64-apple-darwin x86_64-apple-darwin`

## Key Design Decisions

### 1. Flutter over Native
- **Rationale**: Single codebase for testing across all platforms
- **Benefit**: Consistent test scenarios and UI
- **Trade-off**: Additional complexity in FFI setup

### 2. Workspace Structure
- **minidump-handler**: Shared library for all platforms
- **minidump-gen-cli**: Standalone tool for quick testing
- **Benefit**: Clear separation of concerns

### 3. Direct FFI over Platform Channels
- **Rationale**: Direct access to Rust library without platform-specific code
- **Benefit**: Simpler architecture, better performance
- **Trade-off**: More complex initial setup

## Testing Strategy

### Crash Scenarios
Each platform will test:
- SIGSEGV (null pointer dereference)
- SIGBUS (bus error) - where applicable
- SIGABRT (assertion failure)
- Stack overflow
- Divide by zero
- Platform-specific crashes (e.g., EXC_BAD_ACCESS on iOS)

### Validation
- Automated checks for minidump completeness
- Thread state verification
- Memory region validation
- System info accuracy

## Development Workflow

```bash
# Build Rust libraries
cd rust
cargo build --release

# Run Flutter app
flutter run

# Test CLI tool
cd rust/minidump-gen-cli
cargo run -- crash segfault
```

## References

- Original task: minidump-writer TASKS.md: T-012
- minidump-writer source: deps/minidump-writer/src/
- Flutter FFI guide: https://docs.flutter.dev/development/platform-integration/c-interop
- Rust FFI: https://doc.rust-lang.org/nomicon/ffi.html