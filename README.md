# MinidumpWriter Flutter Test App

Cross-platform test harness for the minidump-writer library, supporting iOS, Android, Linux, Windows, and macOS.

## Features

- 🔧 Test minidump generation across all major platforms
- 🧪 Comprehensive crash scenario testing
- 📊 Real-time minidump validation and viewing
- 🚀 Built with Flutter for consistent cross-platform experience
- 🦀 Powered by Rust for native performance

## Quick Start

### Prerequisites

1. **Flutter SDK** (3.0+)
   ```bash
   # Install Flutter from https://flutter.dev/docs/get-started/install
   export PATH="$PATH:$HOME/development/flutter/bin"
   ```

2. **Rust Toolchain**
   ```bash
   curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
   ```

3. **Platform Targets**
   ```bash
   # iOS
   rustup target add aarch64-apple-ios aarch64-apple-ios-sim

   # Android
   rustup target add aarch64-linux-android armv7-linux-androideabi

   # macOS
   rustup target add aarch64-apple-darwin x86_64-apple-darwin
   ```

### Build & Run

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd minidump-writer-flutter-test
   git submodule update --init --recursive
   ```

2. **Build Rust libraries**
   ```bash
   cd rust
   cargo build --release
   cd ..
   ```

3. **Run the Flutter app**
   ```bash
   # List available devices
   flutter devices

   # Run on specific platform
   flutter run -d linux    # Linux
   flutter run -d macos    # macOS
   flutter run -d windows  # Windows
   flutter run -d <device> # iOS/Android device
   ```

## Project Structure

```
minidump-writer-flutter-test/
├── rust/                    # Rust components
│   ├── minidump-handler/   # Core crash handling library
│   └── minidump-gen-cli/   # CLI testing tool
├── lib/                    # Flutter app
│   ├── ffi/               # Dart FFI bindings
│   ├── screens/           # UI screens
│   └── services/          # Business logic
└── deps/                   # Dependencies
    └── minidump-writer/   # Original library (submodule)
```

## Testing Crash Scenarios

### Using the Flutter App

1. Launch the app on your target platform
2. Navigate to "Crash Tests" screen
3. Select a crash scenario:
   - Segmentation Fault
   - Bus Error (Unix only)
   - Abort Signal
   - Stack Overflow
   - Divide by Zero
   - Illegal Instruction

### Using the CLI Tool

```bash
cd rust/minidump-gen-cli

# List available crash types
cargo run -- list

# Trigger specific crash with handler
cargo run -- -H crash segfault

# Generate minidump without crashing
cargo run -- dump --name test_dump
```

## Platform-Specific Notes

### iOS
- Requires macOS with Xcode for building
- Test on both simulator and physical devices
- Minidumps saved to app's Documents directory

### Android
- Requires Android SDK and NDK
- Enable developer mode on physical devices
- Access dumps via Android Studio's Device File Explorer

### Linux
- Ensure GTK development headers are installed:
  ```bash
  sudo apt-get install libgtk-3-dev  # Ubuntu/Debian
  sudo dnf install gtk3-devel         # Fedora
  ```

### Windows
- Requires Visual Studio 2019+ with C++ tools
- Run as Administrator for certain crash scenarios

### macOS
- Requires Xcode command line tools
- May need to allow app in Security & Privacy settings

## Minidump Locations

| Platform | Location |
|----------|----------|
| iOS      | `<App Sandbox>/Documents/minidumps/` |
| Android  | `/data/data/com.example.minidump_writer_test/files/minidumps/` |
| Linux    | `~/.local/share/minidump_writer_test/minidumps/` |
| Windows  | `%APPDATA%\minidump_writer_test\minidumps\` |
| macOS    | `~/Library/Application Support/minidump_writer_test/minidumps/` |

## Development

### Adding New Crash Scenarios

1. Add trigger function in `rust/minidump-handler/src/lib.rs`
2. Export via FFI in the crash_triggers module
3. Add binding in `lib/ffi/minidump_bindings.dart`
4. Create UI button in crash test screen

### Building for Release

```bash
# Build all platforms
./scripts/build_all.sh

# Platform-specific
flutter build apk           # Android APK
flutter build ios          # iOS (requires macOS)
flutter build linux        # Linux
flutter build windows      # Windows
flutter build macos        # macOS
```

## Troubleshooting

### Rust library not found
- Ensure Rust libraries are built: `cd rust && cargo build --release`
- Check library paths in `lib/ffi/minidump_bindings.dart`

### Flutter FFI errors
- Verify Rust target architecture matches Flutter platform
- Clean and rebuild: `flutter clean && flutter pub get`

### Platform-specific issues
- iOS: Check code signing and provisioning profiles
- Android: Verify NDK path in `android/local.properties`
- Linux: Install missing system libraries
- Windows: Run with elevated permissions if needed

## Contributing

1. Follow existing code style and conventions
2. Test on multiple platforms before submitting
3. Update documentation for new features
4. Add tests for new crash scenarios

## License

See LICENSE file in the repository root.

## References

- [minidump-writer](https://github.com/rust-minidump/minidump-writer)
- [Flutter FFI](https://docs.flutter.dev/development/platform-integration/c-interop)
- [Rust FFI](https://doc.rust-lang.org/nomicon/ffi.html)