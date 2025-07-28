//
//  CrashTestView.swift
//  MinidumpWriterExample
//
//  View for testing various crash scenarios
//

import SwiftUI

struct CrashTestView: View {
    @State private var showingAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    @State private var isGenerating = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Normal minidump generation
                    GroupBox("Normal Minidump") {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Generate a minidump of the current app state without crashing.")
                                .font(.footnote)
                                .foregroundColor(.secondary)
                            
                            Button(action: generateNormalMinidump) {
                                Label("Generate Minidump", systemImage: "doc.badge.plus")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.borderedProminent)
                            .disabled(isGenerating)
                        }
                        .padding(.vertical, 5)
                    }
                    
                    // Crash scenarios
                    GroupBox("Crash Scenarios") {
                        VStack(spacing: 15) {
                            Text("⚠️ WARNING: These will crash the app!")
                                .font(.footnote)
                                .foregroundColor(.red)
                                .padding(.bottom, 5)
                            
                            CrashButton(
                                title: "Null Pointer Dereference",
                                description: "SIGSEGV - Access violation",
                                action: crashNullPointer
                            )
                            
                            CrashButton(
                                title: "Bus Error",
                                description: "SIGBUS - Misaligned memory access",
                                action: crashBusError
                            )
                            
                            CrashButton(
                                title: "Assertion Failure",
                                description: "SIGABRT - Abort signal",
                                action: crashAssertion
                            )
                            
                            CrashButton(
                                title: "Stack Overflow",
                                description: "Recursive function overflow",
                                action: crashStackOverflow
                            )
                            
                            CrashButton(
                                title: "Divide by Zero",
                                description: "Arithmetic exception",
                                action: crashDivideByZero
                            )
                            
                            CrashButton(
                                title: "Invalid Memory Access",
                                description: "EXC_BAD_ACCESS",
                                action: crashBadAccess
                            )
                        }
                        .padding(.vertical, 5)
                    }
                    
                    Spacer(minLength: 50)
                }
                .padding()
            }
            .navigationTitle("Crash Tests")
            .alert(isPresented: $showingAlert) {
                Alert(
                    title: Text(alertTitle),
                    message: Text(alertMessage),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
    }
    
    // MARK: - Normal Minidump Generation
    
    private func generateNormalMinidump() {
        isGenerating = true
        
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let filepath = try MinidumpManager.generatePath(prefix: "normal")
                try MinidumpWriter.writeMinidump(to: filepath.path)
                
                DispatchQueue.main.async {
                    self.alertTitle = "Success"
                    self.alertMessage = "Minidump saved as \(filepath.lastPathComponent)"
                    self.showingAlert = true
                    self.isGenerating = false
                }
            } catch {
                DispatchQueue.main.async {
                    self.alertTitle = "Error"
                    self.alertMessage = error.localizedDescription
                    self.showingAlert = true
                    self.isGenerating = false
                }
            }
        }
    }
    
    // MARK: - Crash Scenarios
    
    private func crashNullPointer() {
        #if DEBUG
        MinidumpWriter.triggerSegfault()
        #else
        // Fallback for release builds
        let ptr: UnsafeMutablePointer<Int>? = nil
        ptr!.pointee = 42
        #endif
    }
    
    private func crashBusError() {
        #if DEBUG
        MinidumpWriter.triggerBusError()
        #else
        // Force misaligned access
        let data = Data([0x01, 0x02, 0x03, 0x04])
        data.withUnsafeBytes { bytes in
            let misaligned = bytes.baseAddress! + 1
            let _ = misaligned.bindMemory(to: Int64.self, capacity: 1).pointee
        }
        #endif
    }
    
    private func crashAssertion() {
        #if DEBUG
        MinidumpWriter.triggerAbort()
        #else
        fatalError("Test assertion failure")
        #endif
    }
    
    private func crashStackOverflow() {
        #if DEBUG
        MinidumpWriter.triggerStackOverflow()
        #else
        func recurse(_ n: Int) {
            let array = [Int](repeating: n, count: 1000)
            recurse(n + array[0])
        }
        recurse(0)
        #endif
    }
    
    private func crashDivideByZero() {
        #if DEBUG
        MinidumpWriter.triggerDivideByZero()
        #else
        let zero = 0
        let _ = 42 / zero
        #endif
    }
    
    private func crashBadAccess() {
        #if DEBUG
        MinidumpWriter.triggerSegfault() // Same as null pointer
        #else
        let badPtr = UnsafeMutablePointer<Int>(bitPattern: 0xDEADBEEF)!
        badPtr.pointee = 42
        #endif
    }
}

struct CrashButton: View {
    let title: String
    let description: String
    let action: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack {
                VStack(alignment: .leading) {
                    Text(title)
                        .font(.footnote)
                        .fontWeight(.medium)
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Button(action: action) {
                    Text("Crash")
                        .font(.caption)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                }
                .buttonStyle(.bordered)
                .tint(.red)
            }
        }
        .padding(.vertical, 2)
    }
}