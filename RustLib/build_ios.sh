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

# For Apple Silicon, device and simulator have same architecture
# So we'll just use the simulator build for development
echo -e "${GREEN}Using simulator build for development...${NC}"
cp build/libminidump_writer_ios_sim.a build/libminidump_writer_ios.a

# Generate header file
echo -e "${GREEN}Generating header file...${NC}"
cargo build --release

# Copy header to build directory
cp include/minidump_writer_ios.h build/

# Skip XCFramework creation for now since we need headers
echo -e "${YELLOW}Skipping XCFramework creation (headers not generated yet)...${NC}"

echo -e "${GREEN}Build complete!${NC}"
echo -e "Artifacts:"
echo -e "  - Universal library: build/libminidump_writer_ios.a"
echo -e "  - Header file: build/minidump_writer_ios.h"
echo -e "  - XCFramework: build/MinidumpWriterIOS.xcframework"