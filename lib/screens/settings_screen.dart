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
              // mode can still be ThemeMode.system (no explicit choice made
              // yet), in which case whether dark is actually showing depends
              // on the OS setting — reflect the resolved brightness, not just
              // a literal mode == ThemeMode.dark check.
              final isDark = switch (mode) {
                ThemeMode.dark => true,
                ThemeMode.light => false,
                ThemeMode.system =>
                  MediaQuery.platformBrightnessOf(context) == Brightness.dark,
              };
              return SwitchListTile(
                title: const Text('Dark theme'),
                value: isDark,
                onChanged: (value) => ThemeController.instance.setDark(value),
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
