import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../src/rust/api.dart';
import '../src/rust/frb_generated.dart';

/// Service for managing minidump operations
class MinidumpService {
  MinidumpApi? _api;
  late final String _dumpDirectory;
  bool _initialized = false;
  
  MinidumpService() {
    // API will be initialized in initialize()
  }
  
  /// Initialize the service
  Future<void> initialize() async {
    if (_initialized) return;
    
    // Initialize flutter_rust_bridge
    await RustLib.init();
    _api = MinidumpApi();
    
    // Get platform-specific directory
    _dumpDirectory = await _getDumpDirectory();
    
    // Create directory if it doesn't exist
    final dir = Directory(_dumpDirectory);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    
    // Install crash handlers
    final result = await _api!.installHandlers(dumpPath: _dumpDirectory);
    if (!result.success) {
      throw Exception('Failed to install crash handlers: ${result.error}');
    }
    
    _initialized = true;
  }
  
  /// Get platform-specific dump directory
  Future<String> _getDumpDirectory() async {
    if (Platform.isIOS) {
      final docs = await getApplicationDocumentsDirectory();
      return path.join(docs.path, 'minidumps');
    } else if (Platform.isAndroid) {
      final files = await getApplicationDocumentsDirectory();
      return path.join(files.path, 'minidumps');
    } else if (Platform.isLinux) {
      final home = Platform.environment['HOME'] ?? '';
      return path.join(home, '.local', 'share', 'minidump_writer_test', 'minidumps');
    } else if (Platform.isWindows) {
      final appData = Platform.environment['APPDATA'] ?? '';
      return path.join(appData, 'minidump_writer_test', 'minidumps');
    } else if (Platform.isMacOS) {
      final home = Platform.environment['HOME'] ?? '';
      return path.join(home, 'Library', 'Application Support', 'minidump_writer_test', 'minidumps');
    } else {
      throw UnsupportedError('Platform not supported: ${Platform.operatingSystem}');
    }
  }
  
  /// Write a minidump manually
  Future<String> writeDump({String? filename}) async {
    if (!_initialized) await initialize();
    
    final name = filename ?? 'manual_dump_${DateTime.now().millisecondsSinceEpoch}.dmp';
    final dumpPath = path.join(_dumpDirectory, name);
    
    final result = await _api!.writeDump(path: dumpPath);
    if (!result.success) {
      throw Exception('Failed to write minidump: ${result.error}');
    }
    
    return dumpPath;
  }
  
  /// Trigger a crash (debug builds only)
  Future<void> triggerCrash(CrashType type) async {
    if (!_api!.hasCrashTriggers()) {
      throw Exception('Crash triggers not available in release builds');
    }
    
    await _api!.triggerCrash(crashType: type);
  }
  
  /// Get list of minidump files
  Future<List<MinidumpFile>> getMinidumps() async {
    if (!_initialized) await initialize();
    
    final dir = Directory(_dumpDirectory);
    if (!await dir.exists()) {
      return [];
    }
    
    final files = await dir.list()
        .where((entity) => entity is File && entity.path.endsWith('.dmp'))
        .map((entity) async {
          final file = entity as File;
          final stat = await file.stat();
          return MinidumpFile(
            path: file.path,
            name: path.basename(file.path),
            size: stat.size,
            created: stat.changed,
          );
        })
        .toList();
    
    final minidumps = await Future.wait(files);
    minidumps.sort((a, b) => b.created.compareTo(a.created));
    return minidumps;
  }
  
  /// Delete a minidump file
  Future<void> deleteMinidump(String filepath) async {
    final file = File(filepath);
    if (await file.exists()) {
      await file.delete();
    }
  }
  
  /// Delete all minidump files
  Future<void> deleteAllMinidumps() async {
    final minidumps = await getMinidumps();
    for (final dump in minidumps) {
      await deleteMinidump(dump.path);
    }
  }
  
  /// Get dump directory path
  String get dumpDirectory => _dumpDirectory;
  
  /// Check if service is initialized
  bool get isInitialized => _initialized;
  
  /// Check if crash triggers are available
  bool get hasCrashTriggers => _api?.hasCrashTriggers() ?? false;
}

/// Represents a minidump file
class MinidumpFile {
  final String path;
  final String name;
  final int size;
  final DateTime created;
  
  MinidumpFile({
    required this.path,
    required this.name,
    required this.size,
    required this.created,
  });
  
  /// Get human-readable size
  String get sizeFormatted {
    if (size < 1024) return '$size B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)} KB';
    return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}