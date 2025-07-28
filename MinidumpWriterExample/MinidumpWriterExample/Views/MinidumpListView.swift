//
//  MinidumpListView.swift
//  MinidumpWriterExample
//
//  View for managing and inspecting minidump files
//

import SwiftUI

struct MinidumpListView: View {
    @State private var minidumps: [MinidumpFile] = []
    @State private var selectedMinidump: MinidumpFile?
    @State private var showingDeleteAlert = false
    @State private var showingShareSheet = false
    @State private var shareURL: URL?
    
    var body: some View {
        NavigationView {
            List {
                if minidumps.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "doc.text")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        Text("No minidumps yet")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        Text("Generate minidumps from the Crash Tests tab")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 50)
                } else {
                    ForEach(minidumps) { dump in
                        MinidumpRow(minidump: dump) {
                            selectedMinidump = dump
                        }
                    }
                    .onDelete(perform: deleteMinidumps)
                }
            }
            .navigationTitle("Minidumps")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if !minidumps.isEmpty {
                        Button(action: {
                            showingDeleteAlert = true
                        }) {
                            Label("Delete All", systemImage: "trash")
                        }
                    }
                }
            }
            .refreshable {
                await loadMinidumps()
            }
            .alert("Delete All Minidumps?", isPresented: $showingDeleteAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Delete All", role: .destructive) {
                    deleteAllMinidumps()
                }
            } message: {
                Text("This will permanently delete all minidump files.")
            }
            .sheet(item: $selectedMinidump) { dump in
                MinidumpDetailView(minidump: dump)
            }
        }
        .onAppear {
            Task {
                await loadMinidumps()
            }
        }
    }
    
    @MainActor
    private func loadMinidumps() async {
        do {
            let urls = try MinidumpManager.listMinidumps()
            minidumps = urls.compactMap { url in
                guard let attributes = try? FileManager.default.attributesOfItem(atPath: url.path),
                      let size = attributes[.size] as? Int64,
                      let creationDate = attributes[.creationDate] as? Date else {
                    return nil
                }
                
                return MinidumpFile(
                    url: url,
                    name: url.lastPathComponent,
                    size: size,
                    creationDate: creationDate
                )
            }
        } catch {
            print("Failed to load minidumps: \(error)")
            minidumps = []
        }
    }
    
    private func deleteMinidumps(at offsets: IndexSet) {
        for index in offsets {
            let dump = minidumps[index]
            do {
                try MinidumpManager.deleteMinidump(at: dump.url)
            } catch {
                print("Failed to delete minidump: \(error)")
            }
        }
        Task {
            await loadMinidumps()
        }
    }
    
    private func deleteAllMinidumps() {
        do {
            try MinidumpManager.deleteAllMinidumps()
            Task {
                await loadMinidumps()
            }
        } catch {
            print("Failed to delete all minidumps: \(error)")
        }
    }
}

struct MinidumpFile: Identifiable {
    let id = UUID()
    let url: URL
    let name: String
    let size: Int64
    let creationDate: Date
    
    var formattedSize: String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: size)
    }
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .medium
        return formatter.string(from: creationDate)
    }
    
    var crashType: String? {
        if name.contains("null_pointer") { return "Null Pointer" }
        if name.contains("bus_error") { return "Bus Error" }
        if name.contains("assertion") { return "Assertion" }
        if name.contains("stack_overflow") { return "Stack Overflow" }
        if name.contains("divide_zero") { return "Divide by Zero" }
        if name.contains("bad_access") { return "Bad Access" }
        if name.contains("normal") { return "Normal Dump" }
        return nil
    }
}

struct MinidumpRow: View {
    let minidump: MinidumpFile
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(minidump.name)
                        .font(.footnote)
                        .fontWeight(.medium)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    if let crashType = minidump.crashType {
                        Text(crashType)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color.accentColor.opacity(0.2))
                            .cornerRadius(4)
                    }
                }
                
                HStack {
                    Text(minidump.formattedDate)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text(minidump.formattedSize)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
    }
}

struct MinidumpDetailView: View {
    let minidump: MinidumpFile
    @Environment(\.dismiss) private var dismiss
    @State private var content: String = "Loading..."
    @State private var showingShareSheet = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // File info
                    GroupBox("File Information") {
                        VStack(alignment: .leading, spacing: 10) {
                            InfoRow(label: "Name", value: minidump.name)
                            InfoRow(label: "Size", value: minidump.formattedSize)
                            InfoRow(label: "Created", value: minidump.formattedDate)
                            if let crashType = minidump.crashType {
                                InfoRow(label: "Type", value: crashType)
                            }
                        }
                        .font(.footnote)
                    }
                    
                    // Minidump analysis placeholder
                    GroupBox("Minidump Analysis") {
                        Text("In a production app, this would show:")
                            .font(.footnote)
                            .padding(.bottom, 5)
                        
                        VStack(alignment: .leading, spacing: 5) {
                            Text("• Thread states and stack traces")
                            Text("• System information")
                            Text("• Memory regions")
                            Text("• Exception details")
                            Text("• Module list")
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                    }
                    
                    // Raw content preview
                    GroupBox("Raw Content (First 1KB)") {
                        Text(content)
                            .font(.system(.caption, design: .monospaced))
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding()
            }
            .navigationTitle("Minidump Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingShareSheet = true
                    }) {
                        Label("Share", systemImage: "square.and.arrow.up")
                    }
                }
            }
        }
        .onAppear {
            loadContent()
        }
        .sheet(isPresented: $showingShareSheet) {
            ShareSheet(items: [minidump.url])
        }
    }
    
    private func loadContent() {
        do {
            let data = try Data(contentsOf: minidump.url)
            let preview = data.prefix(1024)
            content = preview.map { String(format: "%02X", $0) }
                .enumerated()
                .map { $0.offset % 16 == 0 && $0.offset > 0 ? "\n\($0.element)" : $0.element }
                .joined(separator: " ")
        } catch {
            content = "Failed to load minidump: \(error.localizedDescription)"
        }
    }
}

struct InfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label + ":")
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}