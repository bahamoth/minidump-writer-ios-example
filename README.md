# MinidumpWriter iOS Example

Test harness for minidump-writer library on iOS.

## Setup

```bash
# Clone with submodules
git clone https://github.com/your-repo/minidump-writer-ios-example.git
cd minidump-writer-ios-example
git submodule update --init --recursive

# Install Rust targets
rustup target add aarch64-apple-ios
rustup target add aarch64-apple-ios-sim

# Build Rust library
cd RustLib
./build_ios.sh
cd ..

# Open in Xcode
open MinidumpWriterExample/MinidumpWriterExample.xcodeproj
```

## Usage

1. **Build & Run** (⌘R) on ARM64 device/simulator
2. **Test crashes** in "Crash Tests" tab
3. **View dumps** in "Minidumps" tab after crash & restart

## Dump Location

- **Path**: `Documents/minidumps/` in app sandbox
- **Access**: Via app's share function or iTunes File Sharing

## Requirements

- Xcode 14.0+
- iOS 15.0+
- ARM64 only (no x86 support)