# Flutter-Rust FFI Integration for MinidumpWriter

## Overview

This document describes the FFI (Foreign Function Interface) integration between Flutter and the Rust minidump-writer library using flutter_rust_bridge.

## Architecture

```
Flutter App (Dart)
    ↓ flutter_rust_bridge
minidump-flutter-bridge (Rust FFI wrapper)
    ↓
minidump-handler (Rust library)
    ↓
minidump-writer (Core library)
```

## Implementation Details

### 1. Rust Workspace Structure

The Rust code is organized in a workspace under `/rust/`:

- `minidump-handler/`: Core crash handling library
- `minidump-flutter-bridge/`: FFI bridge for Flutter
- `minidump-gen-cli/`: Command-line testing tool

### 2. Flutter-Rust Bridge Configuration

Configuration file: `flutter_rust_bridge.yaml`
```yaml
rust_input: "crate::api"
rust_root: "rust/minidump-flutter-bridge/"
dart_output: "lib/src/rust"
rust_output: "rust/minidump-flutter-bridge/src/frb_generated.rs"
dart_entrypoint_class_name: "RustLib"
```

### 3. API Design

The bridge exposes the following API through `MinidumpApi`:

```dart
class MinidumpApi {
  // Core functionality
  Future<MinidumpResult> writeDump({required String path});
  Future<MinidumpResult> installHandlers({required String dumpPath});
  
  // Testing helpers
  bool hasCrashTriggers();
  Future<void> triggerCrash({required CrashType crashType});
}
```

### 4. Platform-Specific Library Loading

The `MinidumpService` handles platform-specific library loading:

- **macOS**: Loads `libminidump_flutter_bridge.dylib` from `macos/` directory
- **iOS**: Uses `ExternalLibrary.process()` for static linking
- **Android**: Loads `libminidump_flutter_bridge.so`
- **Linux**: Loads `libminidump_flutter_bridge.so`
- **Windows**: Loads `minidump_flutter_bridge.dll`

## Build Process

### Prerequisites

1. Install flutter_rust_bridge_codegen:
   ```bash
   cargo install flutter_rust_bridge_codegen
   ```

2. Install ffigen dependency:
   ```yaml
   dev_dependencies:
     ffigen: ^13.0.0
   ```

### Building

1. Generate FFI bindings:
   ```bash
   flutter_rust_bridge_codegen generate
   ```

2. Build Rust libraries:
   ```bash
   cd rust
   cargo build --release
   ```

3. Copy libraries to platform directories:
   ```bash
   # macOS
   cp rust/target/release/libminidump_flutter_bridge.dylib macos/
   
   # Other platforms handled by build_runner.sh
   ```

### Running

```bash
flutter run -d macos  # or ios, android, linux, windows
```

## Integration Points

### 1. MinidumpService (Dart)

Located at `lib/services/minidump_service.dart`, this service:
- Initializes the FFI bridge
- Manages platform-specific dump directories
- Provides high-level API for crash handling

### 2. Crash Types

The following crash types are supported for testing:
- Segfault
- Abort
- BusError
- DivideByZero
- IllegalInstruction
- StackOverflow

### 3. Directory Structure

Minidumps are saved to platform-specific directories:
- **macOS**: `~/Library/Application Support/minidump_writer_test/minidumps/`
- **iOS**: `<app_documents>/minidumps/`
- **Android**: `<app_documents>/minidumps/`
- **Linux**: `~/.local/share/minidump_writer_test/minidumps/`
- **Windows**: `%APPDATA%/minidump_writer_test/minidumps/`

## Testing

1. Launch the app
2. Navigate to "Crash Tests" to trigger test crashes
3. Use "Generate Manual Dump" to create a minidump without crashing
4. View generated minidumps in "View Minidumps"

## Troubleshooting

### Library Not Found

If the app fails to find the library:
1. Ensure the library is built: `cd rust && cargo build --release`
2. Check the library is in the correct location
3. Verify the library name matches the platform convention

### FFI Generation Errors

If flutter_rust_bridge_codegen fails:
1. Ensure you have the latest version installed
2. Check that `rust_root` path is correct in config
3. Verify the Rust code compiles independently

### Platform-Specific Issues

- **iOS**: Requires proper signing and entitlements
- **Android**: Ensure NDK is properly configured
- **Windows**: May need Visual C++ redistributables

## Next Steps

1. Complete iOS build configuration with proper framework setup
2. Add Android JNI configuration
3. Implement Linux and Windows platform support
4. Add automated tests for FFI integration
5. Create CI/CD pipeline for multi-platform builds