//
//  MinidumpWriterExampleApp.swift
//  MinidumpWriterExample
//
//  Main app entry point
//

import SwiftUI

@main
struct MinidumpWriterExampleApp: App {
    init() {
        // Ensure minidumps directory exists on startup
        do {
            try MinidumpManager.ensureDirectoryExists()
            print("Minidumps directory: \(MinidumpManager.minidumpsDirectory)")
            
            // Test library functionality
            if MinidumpWriter.test() {
                print("MinidumpWriter library test passed")
            } else {
                print("WARNING: MinidumpWriter library test failed")
            }
            
            // Install crash handlers
            try MinidumpWriter.installCrashHandlers(
                dumpPath: MinidumpManager.minidumpsDirectory.path
            )
            print("Crash handlers installed successfully")
        } catch {
            print("Failed to initialize app: \(error)")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}