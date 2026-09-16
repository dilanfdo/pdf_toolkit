import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../services/consent_service.dart';
import '../services/theme_controller.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _showPrivacyOptions = false;

  @override
  void initState() {
    super.initState();
    _loadPrivacyOptionsVisibility();
  }

  Future<void> _loadPrivacyOptionsVisibility() async {
    final status = await ConsentService.instance.privacyOptionsRequirement;
    if (!mounted) return;
    setState(() {
      _showPrivacyOptions = status == PrivacyOptionsRequirementStatus.required;
    });
  }

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
          if (_showPrivacyOptions)
            ListTile(
              leading: const Icon(Icons.privacy_tip_outlined),
              title: const Text('Privacy options'),
              subtitle: const Text('Manage ad consent'),
              onTap: () async {
                await ConsentService.instance.showPrivacyOptionsForm();
                if (!mounted) return;
                _loadPrivacyOptionsVisibility();
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
