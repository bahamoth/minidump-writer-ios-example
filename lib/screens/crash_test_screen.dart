import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import '../services/minidump_service.dart';
import '../src/rust/api.dart';

class CrashTestScreen extends StatelessWidget {
  final MinidumpService minidumpService;

  const CrashTestScreen({super.key, required this.minidumpService});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crash Tests'),
        backgroundColor: Colors.orange,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              color: Colors.orange.shade50,
              child: const Padding(
                padding: EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Icon(Icons.warning, color: Colors.orange, size: 32),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Warning!',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'These tests will crash the app. Make sure to save any important data before proceeding.',
                            style: TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            if (!minidumpService.hasCrashTriggers)
              _buildReleaseBuildWarning()
            else
              _buildCrashButtons(context),
          ],
        ),
      ),
    );
  }

  Widget _buildReleaseBuildWarning() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.info_outline, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'Crash triggers not available',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            'This appears to be a release build.\nCrash triggers are only available in debug builds.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildCrashButtons(BuildContext context) {
    return Expanded(
      child: ListView(
        children: [
          _buildCrashButton(
            context,
            title: 'Segmentation Fault',
            subtitle: 'Null pointer dereference causing SIGSEGV',
            icon: Icons.memory,
            crashType: CrashType.segfault,
          ),
          _buildCrashButton(
            context,
            title: 'Abort Signal',
            subtitle: 'Process abort causing SIGABRT',
            icon: Icons.stop_circle,
            crashType: CrashType.abort,
          ),
          if (!Platform.isWindows)
            _buildCrashButton(
              context,
              title: 'Bus Error',
              subtitle: 'Misaligned memory access causing SIGBUS',
              icon: Icons.error,
              crashType: CrashType.busError,
            ),
          _buildCrashButton(
            context,
            title: 'Divide by Zero',
            subtitle: 'Integer division by zero causing SIGFPE',
            icon: Icons.calculate,
            crashType: CrashType.divideByZero,
          ),
          _buildCrashButton(
            context,
            title: 'Illegal Instruction',
            subtitle: 'Invalid CPU instruction causing SIGILL',
            icon: Icons.computer,
            crashType: CrashType.illegalInstruction,
          ),
          _buildCrashButton(
            context,
            title: 'Stack Overflow',
            subtitle: 'Recursive function causing stack exhaustion',
            icon: Icons.layers,
            crashType: CrashType.stackOverflow,
          ),
        ],
      ),
    );
  }

  Widget _buildCrashButton(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required CrashType crashType,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icon, size: 32, color: Colors.red),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => _showCrashConfirmation(context, title, crashType),
      ),
    );
  }

  void _showCrashConfirmation(BuildContext context, String crashName, CrashType crashType) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Trigger $crashName?'),
          content: const Text(
            'This will crash the application immediately. '
            'A minidump will be generated if crash handlers are properly installed.\n\n'
            'The app will need to be restarted after the crash.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Small delay to allow dialog to close
                Future.delayed(const Duration(milliseconds: 500), () async {
                  await minidumpService.triggerCrash(crashType);
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Crash App'),
            ),
          ],
        );
      },
    );
  }
}