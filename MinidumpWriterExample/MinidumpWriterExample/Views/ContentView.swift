//
//  ContentView.swift
//  MinidumpWriterExample
//
//  Main view with tabs for different test scenarios
//

import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Crash test scenarios
            CrashTestView()
                .tabItem {
                    Label("Crash Tests", systemImage: "exclamationmark.triangle")
                }
                .tag(0)
            
            // Minidump file management
            MinidumpListView()
                .tabItem {
                    Label("Minidumps", systemImage: "doc.text")
                }
                .tag(1)
            
            // About/Info view
            AboutView()
                .tabItem {
                    Label("About", systemImage: "info.circle")
                }
                .tag(2)
        }
    }
}

struct AboutView: View {
    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 20) {
                Text("MinidumpWriter iOS Example")
                    .font(.largeTitle)
                    .padding(.bottom)
                
                GroupBox("Purpose") {
                    Text("This app demonstrates and tests the minidump-writer library's iOS capabilities. It's designed to verify that all minidump contexts are properly captured on iOS devices and simulators.")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                        .padding(.vertical, 5)
                }
                
                GroupBox("Testing Features") {
                    VStack(alignment: .leading, spacing: 10) {
                        FeatureRow(icon: "checkmark.circle", text: "Thread state capture")
                        FeatureRow(icon: "checkmark.circle", text: "System information")
                        FeatureRow(icon: "checkmark.circle", text: "Memory regions")
                        FeatureRow(icon: "checkmark.circle", text: "Exception handling")
                        FeatureRow(icon: "checkmark.circle", text: "File system persistence")
                    }
                    .font(.footnote)
                    .padding(.vertical, 5)
                }
                
                GroupBox("Architecture") {
                    VStack(alignment: .leading, spacing: 5) {
                        Text("• Platform: ARM64 only")
                        Text("• Targets: iOS 15.0+")
                        Text("• Integration: Swift ↔ Rust FFI")
                    }
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .padding(.vertical, 5)
                }
                
                Spacer()
                
                Text("Version 1.0.0")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
            .padding()
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.green)
                .frame(width: 20)
            Text(text)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}