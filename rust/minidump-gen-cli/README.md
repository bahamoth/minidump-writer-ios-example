# minidump-gen

A CLI tool for generating minidumps and testing crash scenarios. This tool helps test the minidump-writer library on various platforms including macOS, iOS simulator, and iOS devices.

## Features

- Generate minidumps of the current process without crashing
- Trigger various crash types to test crash handling
- Install signal handlers to automatically capture crash dumps
- Cross-platform support (macOS, iOS, Linux)

## Installation

```bash
cd minidump-gen
cargo build --release
```

## Usage

### Generate a manual dump

Create a minidump of the current process without crashing:

```bash
minidump-gen dump --name my_dump
```

### Test crash scenarios

Install crash handler and trigger a specific crash:

```bash
# Install handler (-H) and trigger segfault
minidump-gen -H crash segfault

# Other crash types:
# - bus-error
# - abort
# - divide-by-zero
# - illegal-instruction
# - stack-overflow
```

### List available crash types

```bash
minidump-gen list
```

### Interactive mode

Run with crash handler installed and wait for crashes:

```bash
# Wait indefinitely
minidump-gen interactive

# With timeout (seconds)
minidump-gen interactive --timeout 60
```

### Options

- `-o, --output <DIR>`: Output directory for minidumps (default: `./dumps`)
- `-p, --prefix <PREFIX>`: Filename prefix for dumps (default: `crash`)
- `-H, --install-handler`: Install crash handler before executing command

## Examples

```bash
# Generate manual dump in custom directory
minidump-gen -o /tmp/dumps dump --name test

# Test segfault with custom prefix
minidump-gen -H -p myapp crash segfault

# Run in background with handler
minidump-gen -o ~/crash_dumps interactive --timeout 3600 &
```

## Building for iOS

To build for iOS simulator or device:

```bash
# iOS Simulator (ARM64)
cargo build --target aarch64-apple-ios-sim

# iOS Device
cargo build --target aarch64-apple-ios
```

## Testing

The generated minidump files can be analyzed using tools like:
- `minidump-stackwalk` from Breakpad
- `minidump-2-core` to convert to core dumps
- Visual Studio or other debuggers that support minidump format