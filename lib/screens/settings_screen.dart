import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text('Dark theme'),
            value: Theme.of(context).brightness == Brightness.dark,
            onChanged: null, // TODO: wire to a theme controller
          ),
          ListTile(
            leading: const Icon(Icons.block),
            title: const Text('Remove ads'),
            subtitle: const Text('Coming soon'),
            enabled: false,
          ),
        ],
      ),
    );
  }
}
