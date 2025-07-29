#!/bin/bash
set -e

echo "🔧 Building Rust libraries for all platforms..."

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to build for a specific target
build_target() {
    local TARGET=$1
    local PLATFORM=$2
    
    echo -e "${BLUE}Building for $PLATFORM ($TARGET)...${NC}"
    
    cd rust
    
    if rustup target list | grep -q "$TARGET (installed)"; then
        cargo build --release --target $TARGET
        echo -e "${GREEN}✓ $PLATFORM build complete${NC}"
    else
        echo "⚠️  Target $TARGET not installed. Run: rustup target add $TARGET"
    fi
    
    cd ..
}

# Install flutter_rust_bridge_codegen if not present
if ! command -v flutter_rust_bridge_codegen &> /dev/null; then
    echo "Installing flutter_rust_bridge_codegen..."
    cargo install flutter_rust_bridge_codegen
fi

# Generate FFI bindings
echo -e "${BLUE}Generating FFI bindings...${NC}"
flutter_rust_bridge_codegen generate

# Build for each platform
echo -e "${BLUE}Building platform libraries...${NC}"

# iOS
if [[ "$OSTYPE" == "darwin"* ]]; then
    build_target "aarch64-apple-ios" "iOS Device"
    build_target "aarch64-apple-ios-sim" "iOS Simulator"
    build_target "x86_64-apple-ios" "iOS Simulator (Intel)"
    
    # Create universal library for iOS
    echo -e "${BLUE}Creating iOS universal library...${NC}"
    mkdir -p ios/Frameworks
    lipo -create \
        rust/target/aarch64-apple-ios/release/libminidump_flutter_bridge.a \
        rust/target/aarch64-apple-ios-sim/release/libminidump_flutter_bridge.a \
        -output ios/Frameworks/libminidump_flutter_bridge.a
fi

# macOS
if [[ "$OSTYPE" == "darwin"* ]]; then
    build_target "aarch64-apple-darwin" "macOS (Apple Silicon)"
    build_target "x86_64-apple-darwin" "macOS (Intel)"
    
    # Create universal library for macOS
    echo -e "${BLUE}Creating macOS universal library...${NC}"
    lipo -create \
        rust/target/aarch64-apple-darwin/release/libminidump_flutter_bridge.dylib \
        rust/target/x86_64-apple-darwin/release/libminidump_flutter_bridge.dylib \
        -output macos/libminidump_flutter_bridge.dylib
fi

# Android
build_target "aarch64-linux-android" "Android ARM64"
build_target "armv7-linux-androideabi" "Android ARMv7"
build_target "i686-linux-android" "Android x86"
build_target "x86_64-linux-android" "Android x86_64"

# Copy Android libraries
if [ -d "rust/target/aarch64-linux-android/release" ]; then
    echo -e "${BLUE}Copying Android libraries...${NC}"
    mkdir -p android/app/src/main/jniLibs/{arm64-v8a,armeabi-v7a,x86,x86_64}
    
    cp rust/target/aarch64-linux-android/release/libminidump_flutter_bridge.so \
       android/app/src/main/jniLibs/arm64-v8a/ 2>/dev/null || true
    cp rust/target/armv7-linux-androideabi/release/libminidump_flutter_bridge.so \
       android/app/src/main/jniLibs/armeabi-v7a/ 2>/dev/null || true
    cp rust/target/i686-linux-android/release/libminidump_flutter_bridge.so \
       android/app/src/main/jniLibs/x86/ 2>/dev/null || true
    cp rust/target/x86_64-linux-android/release/libminidump_flutter_bridge.so \
       android/app/src/main/jniLibs/x86_64/ 2>/dev/null || true
fi

# Linux
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    build_target "x86_64-unknown-linux-gnu" "Linux x86_64"
    
    # Copy Linux library
    cp rust/target/x86_64-unknown-linux-gnu/release/libminidump_flutter_bridge.so \
       linux/
fi

# Windows
if [[ "$OSTYPE" == "msys" || "$OSTYPE" == "cygwin" ]]; then
    build_target "x86_64-pc-windows-msvc" "Windows x86_64"
    
    # Copy Windows library
    cp rust/target/x86_64-pc-windows-msvc/release/minidump_flutter_bridge.dll \
       windows/
fi

echo -e "${GREEN}✅ Build complete!${NC}"