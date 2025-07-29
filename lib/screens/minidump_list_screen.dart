import 'dart:io';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../services/minidump_service.dart';

class MinidumpListScreen extends StatefulWidget {
  final MinidumpService minidumpService;

  const MinidumpListScreen({super.key, required this.minidumpService});

  @override
  State<MinidumpListScreen> createState() => _MinidumpListScreenState();
}

class _MinidumpListScreenState extends State<MinidumpListScreen> {
  List<MinidumpFile>? _minidumps;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMinidumps();
  }

  Future<void> _loadMinidumps() async {
    try {
      final dumps = await widget.minidumpService.getMinidumps();
      setState(() {
        _minidumps = dumps;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load minidumps: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Minidumps'),
        actions: [
          if (_minidumps?.isNotEmpty ?? false)
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              onPressed: _confirmDeleteAll,
              tooltip: 'Delete all',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _minidumps == null || _minidumps!.isEmpty
              ? _buildEmptyView()
              : _buildMinidumpList(),
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.folder_open,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No minidumps found',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Generate a manual dump or trigger a crash\nto see minidumps here',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Go Back'),
          ),
        ],
      ),
    );
  }

  Widget _buildMinidumpList() {
    return RefreshIndicator(
      onRefresh: _loadMinidumps,
      child: ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: _minidumps!.length,
        itemBuilder: (context, index) {
          final dump = _minidumps![index];
          return _buildMinidumpCard(dump);
        },
      ),
    );
  }

  Widget _buildMinidumpCard(MinidumpFile dump) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: const Icon(Icons.file_present, size: 40),
        title: Text(
          dump.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Size: ${dump.sizeFormatted}'),
            Text('Created: ${_formatDateTime(dump.created)}'),
          ],
        ),
        isThreeLine: true,
        trailing: PopupMenuButton<String>(
          onSelected: (value) => _handleMenuAction(value, dump),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'share',
              child: Row(
                children: [
                  Icon(Icons.share, size: 20),
                  SizedBox(width: 8),
                  Text('Share'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, size: 20, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Delete', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-'
        '${dateTime.day.toString().padLeft(2, '0')} '
        '${dateTime.hour.toString().padLeft(2, '0')}:'
        '${dateTime.minute.toString().padLeft(2, '0')}:'
        '${dateTime.second.toString().padLeft(2, '0')}';
  }

  void _handleMenuAction(String action, MinidumpFile dump) {
    switch (action) {
      case 'share':
        _shareDump(dump);
        break;
      case 'delete':
        _confirmDelete(dump);
        break;
    }
  }

  Future<void> _shareDump(MinidumpFile dump) async {
    try {
      final file = XFile(dump.path);
      await Share.shareXFiles(
        [file],
        subject: 'Minidump: ${dump.name}',
        text: 'Minidump file generated on ${_formatDateTime(dump.created)}',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to share minidump: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _confirmDelete(MinidumpFile dump) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Minidump?'),
        content: Text('Are you sure you want to delete "${dump.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteDump(dump);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteDump(MinidumpFile dump) async {
    try {
      await widget.minidumpService.deleteMinidump(dump.path);
      await _loadMinidumps();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Minidump deleted')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete minidump: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _confirmDeleteAll() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete All Minidumps?'),
        content: Text(
          'Are you sure you want to delete all ${_minidumps!.length} minidumps?\n\n'
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteAllDumps();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete All'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteAllDumps() async {
    try {
      await widget.minidumpService.deleteAllMinidumps();
      await _loadMinidumps();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All minidumps deleted')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete minidumps: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}