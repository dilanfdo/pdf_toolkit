import 'dart:io';
import 'package:flutter/material.dart';
import '../services/ad_service.dart';
import 'result_screen.dart';

/// Runs [task] with a progress UI, then shows the result or an error.
class ProcessingScreen extends StatefulWidget {
  final String title;
  final Future<File> Function() task;

  const ProcessingScreen({super.key, required this.title, required this.task});

  @override
  State<ProcessingScreen> createState() => _ProcessingScreenState();
}

class _ProcessingScreenState extends State<ProcessingScreen> {
  String? _error;

  @override
  void initState() {
    super.initState();
    _run();
  }

  Future<void> _run() async {
    try {
      final file = await widget.task();
      await AdService.instance.maybeShowInterstitialAfterExport();
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => ResultScreen(file: file)),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Center(
        child: _error == null
            ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 24),
                  Text('Processing…', style: Theme.of(context).textTheme.bodyLarge),
                ],
              )
            : Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.error_outline,
                        size: 48, color: Theme.of(context).colorScheme.error),
                    const SizedBox(height: 16),
                    Text('Something went wrong', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Text(_error!, textAlign: TextAlign.center),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Go back'),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
