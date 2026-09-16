import 'dart:io';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'home_screen.dart';

class ResultScreen extends StatelessWidget {
  final File file;

  const ResultScreen({super.key, required this.file});

  String _formatSize(int bytes) {
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(0)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    final sizeBytes = file.lengthSync();

    return Scaffold(
      appBar: AppBar(title: const Text('Done')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle,
                  size: 64, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 16),
              Text(file.uri.pathSegments.last,
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 4),
              Text(_formatSize(sizeBytes),
                  style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 32),
              FilledButton.icon(
                onPressed: () => SharePlus.instance.share(
                  ShareParams(files: [XFile(file.path)]),
                ),
                icon: const Icon(Icons.share),
                label: const Text('Share'),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const HomeScreen()),
                  (route) => false,
                ),
                child: const Text('Back to home'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
