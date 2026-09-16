import 'package:flutter/material.dart';
import '../services/theme_controller.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          ValueListenableBuilder<ThemeMode>(
            valueListenable: ThemeController.instance.mode,
            builder: (context, mode, _) {
              return SwitchListTile(
                title: const Text('Dark theme'),
                value: mode == ThemeMode.dark,
                onChanged: (isDark) => ThemeController.instance.setDark(isDark),
              );
            },
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
