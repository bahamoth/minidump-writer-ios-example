//
//  MinidumpWriter.swift
//  MinidumpWriterExample
//
//  Swift wrapper for minidump-writer Rust FFI
//

import Foundation

/// Errors that can occur during minidump operations
enum MinidumpError: Error, LocalizedError {
    case initializationFailed
    case writeFailed(String)
    case invalidPath
    
    var errorDescription: String? {
        switch self {
        case .initializationFailed:
            return "Failed to initialize MinidumpWriter"
        case .writeFailed(let message):
            return "Failed to write minidump: \(message)"
        case .invalidPath:
            return "Invalid file path"
        }
    }
}

/// Exception information for crash context
struct ExceptionInfo {
    let type: UInt32
    let code: UInt64
    let address: UInt64
}

/// Swift wrapper for the minidump-writer library
class MinidumpWriter {
    private var handle: OpaquePointer?
    
    /// Initialize a new MinidumpWriter instance
    init() throws {
        guard let handle = minidump_writer_ios_create() else {
            throw MinidumpError.initializationFailed
        }
        self.handle = handle
    }
    
    deinit {
        if let handle = handle {
            minidump_writer_ios_free(handle)
        }
    }
    
    /// Write a minidump to the specified file path
    /// - Parameter path: The file path where the minidump should be saved
    /// - Throws: MinidumpError if the operation fails
    func writeMinidump(to path: String) throws {
        guard let handle = handle else {
            throw MinidumpError.initializationFailed
        }
        
        let result = path.withCString { cPath in
            minidump_writer_ios_write_dump(handle, cPath)
        }
        
        if !result.success {
            let errorMessage = result.error_message != nil
                ? String(cString: result.error_message!)
                : "Unknown error"
            
            if result.error_message != nil {
                minidump_writer_ios_free_error_message(result.error_message)
            }
            
            throw MinidumpError.writeFailed(errorMessage)
        }
    }
    
    /// Write a minidump with exception context
    /// - Parameters:
    ///   - path: The file path where the minidump should be saved
    ///   - exception: Exception information to include in the dump
    /// - Throws: MinidumpError if the operation fails
    func writeMinidump(to path: String, withException exception: ExceptionInfo) throws {
        guard let handle = handle else {
            throw MinidumpError.initializationFailed
        }
        
        let result = path.withCString { cPath in
            minidump_writer_ios_write_dump_with_exception(
                handle,
                cPath,
                exception.type,
                exception.code,
                exception.address
            )
        }
        
        if !result.success {
            let errorMessage = result.error_message != nil
                ? String(cString: result.error_message!)
                : "Unknown error"
            
            if result.error_message != nil {
                minidump_writer_ios_free_error_message(result.error_message)
            }
            
            throw MinidumpError.writeFailed(errorMessage)
        }
    }
    
    /// Test if the library is working properly
    /// - Returns: true if the library is functional
    static func test() -> Bool {
        return minidump_writer_ios_test() == 1
    }
    
    /// Install crash handlers to automatically generate minidumps
    /// - Parameter dumpPath: Directory where crash dumps will be saved
    /// - Throws: MinidumpError if installation fails
    static func installCrashHandlers(dumpPath: String) throws {
        let result = dumpPath.withCString { cPath in
            minidump_writer_ios_install_handlers(cPath)
        }
        
        if !result.success {
            let errorMessage = result.error_message != nil
                ? String(cString: result.error_message!)
                : "Failed to install crash handlers"
            
            if result.error_message != nil {
                minidump_writer_ios_free_error_message(result.error_message)
            }
            
            throw MinidumpError.writeFailed(errorMessage)
        }
    }
}

/// Utility class for managing minidump files
class MinidumpManager {
    /// Get the default directory for storing minidumps
    static var minidumpsDirectory: URL {
        let documentsPath = FileManager.default.urls(for: .documentDirectory,
                                                      in: .userDomainMask).first!
        return documentsPath.appendingPathComponent("minidumps")
    }
    
    /// Ensure the minidumps directory exists
    static func ensureDirectoryExists() throws {
        try FileManager.default.createDirectory(at: minidumpsDirectory,
                                                withIntermediateDirectories: true,
                                                attributes: nil)
    }
    
    /// Generate a unique filename for a minidump
    static func generateFilename(prefix: String = "dump") -> String {
        let timestamp = ISO8601DateFormatter().string(from: Date())
            .replacingOccurrences(of: ":", with: "-")
            .replacingOccurrences(of: ".", with: "-")
        return "\(prefix)_\(timestamp).dmp"
    }
    
    /// List all minidump files
    static func listMinidumps() throws -> [URL] {
        let contents = try FileManager.default.contentsOfDirectory(
            at: minidumpsDirectory,
            includingPropertiesForKeys: [.creationDateKey],
            options: .skipsHiddenFiles
        )
        
        return contents
            .filter { $0.pathExtension == "dmp" }
            .sorted { url1, url2 in
                let date1 = try? url1.resourceValues(forKeys: [.creationDateKey]).creationDate
                let date2 = try? url2.resourceValues(forKeys: [.creationDateKey]).creationDate
                return (date1 ?? Date.distantPast) > (date2 ?? Date.distantPast)
            }
    }
    
    /// Delete a minidump file
    static func deleteMinidump(at url: URL) throws {
        try FileManager.default.removeItem(at: url)
    }
    
    /// Delete all minidump files
    static func deleteAllMinidumps() throws {
        let dumps = try listMinidumps()
        for dump in dumps {
            try deleteMinidump(at: dump)
        }
    }
}