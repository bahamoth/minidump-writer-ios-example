#!/bin/bash
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}Building minidump-writer iOS library...${NC}"

# Ensure we have the required targets
echo -e "${YELLOW}Checking Rust iOS targets...${NC}"
rustup target add aarch64-apple-ios
rustup target add aarch64-apple-ios-sim

# Clean previous builds
echo -e "${YELLOW}Cleaning previous builds...${NC}"
rm -rf build
mkdir -p build

# Build for iOS device (ARM64)
echo -e "${GREEN}Building for iOS device (arm64)...${NC}"
cargo build --target aarch64-apple-ios --release
cp target/aarch64-apple-ios/release/libminidump_writer_ios.a build/libminidump_writer_ios_device.a

# Build for iOS simulator (ARM64)
echo -e "${GREEN}Building for iOS simulator (arm64)...${NC}"
cargo build --target aarch64-apple-ios-sim --release
cp target/aarch64-apple-ios-sim/release/libminidump_writer_ios.a build/libminidump_writer_ios_sim.a

# Create universal library using lipo
echo -e "${GREEN}Creating universal library...${NC}"
lipo -create \
    build/libminidump_writer_ios_device.a \
    build/libminidump_writer_ios_sim.a \
    -output build/libminidump_writer_ios.a

# Generate header file
echo -e "${GREEN}Generating header file...${NC}"
cargo build --release

# Copy header to build directory
cp include/minidump_writer_ios.h build/

# Create xcframework (optional - for better integration)
echo -e "${GREEN}Creating XCFramework...${NC}"
xcodebuild -create-xcframework \
    -library build/libminidump_writer_ios_device.a \
    -headers include \
    -library build/libminidump_writer_ios_sim.a \
    -headers include \
    -output build/MinidumpWriterIOS.xcframework

echo -e "${GREEN}Build complete!${NC}"
echo -e "Artifacts:"
echo -e "  - Universal library: build/libminidump_writer_ios.a"
echo -e "  - Header file: build/minidump_writer_ios.h"
echo -e "  - XCFramework: build/MinidumpWriterIOS.xcframework"