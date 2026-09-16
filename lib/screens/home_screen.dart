import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../models/pdf_tool.dart';
import '../services/ad_service.dart';
import '../widgets/tool_card.dart';
import 'file_picker_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  BannerAd? _bannerAd;

  @override
  void initState() {
    super.initState();
    _bannerAd = AdService.instance.createBannerAd(
      onLoaded: (ad) => setState(() {}),
    );
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  void _openTool(PdfTool tool) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => FilePickerScreen(tool: tool)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PDFly'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: GridView.count(
            crossAxisCount: 2,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            children: PdfTool.values
                .map((tool) => ToolCard(tool: tool, onTap: () => _openTool(tool)))
                .toList(),
          ),
        ),
      ),
      bottomNavigationBar: _bannerAd == null
          ? null
          : SizedBox(
              height: _bannerAd!.size.height.toDouble(),
              width: _bannerAd!.size.width.toDouble(),
              child: AdWidget(ad: _bannerAd!),
            ),
    );
  }
}
