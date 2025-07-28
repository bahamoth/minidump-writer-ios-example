//
//  MinidumpWriter.swift
//  MinidumpWriterExample
//
//  Swift wrapper for minidump-writer Rust FFI
//

import Foundation

/// Errors that can occur during minidump operations
enum MinidumpError: Error, LocalizedError {
    case writeFailed(String)
    case installHandlersFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .writeFailed(let message):
            return "Failed to write minidump: \(message)"
        case .installHandlersFailed(let message):
            return "Failed to install crash handlers: \(message)"
        }
    }
}

/// Swift wrapper for the minidump-writer library
class MinidumpWriter {
    
    /// Write a minidump to the specified file path
    /// - Parameter path: The file path where the minidump should be saved
    /// - Throws: MinidumpError if the operation fails
    static func writeMinidump(to path: String) throws {
        let result = path.withCString { cPath in
            minidump_writer_ios_write_dump(cPath)
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
            
            throw MinidumpError.installHandlersFailed(errorMessage)
        }
    }
    
    // Crash trigger functions for testing (debug builds only)
    #if DEBUG
    static func triggerSegfault() {
        minidump_writer_ios_trigger_segfault()
    }
    
    static func triggerAbort() {
        minidump_writer_ios_trigger_abort()
    }
    
    static func triggerBusError() {
        minidump_writer_ios_trigger_bus_error()
    }
    
    static func triggerDivideByZero() {
        minidump_writer_ios_trigger_divide_by_zero()
    }
    
    static func triggerIllegalInstruction() {
        minidump_writer_ios_trigger_illegal_instruction()
    }
    
    static func triggerStackOverflow() {
        minidump_writer_ios_trigger_stack_overflow()
    }
    #endif
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
    
    /// Generate a full path for a new minidump
    static func generatePath(prefix: String = "dump") throws -> URL {
        try ensureDirectoryExists()
        return minidumpsDirectory.appendingPathComponent(generateFilename(prefix: prefix))
    }
    
    /// List all minidump files
    static func listMinidumps() throws -> [URL] {
        try ensureDirectoryExists()
        
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
    
    /// Get the size of a minidump file
    static func getMinidumpSize(at url: URL) -> Int64? {
        let attributes = try? FileManager.default.attributesOfItem(atPath: url.path)
        return attributes?[.size] as? Int64
    }
}