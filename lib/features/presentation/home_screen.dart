import 'package:flutter/material.dart';
import 'package:interacting_bear/features/presentation/bear_animation_widget.dart';
import 'package:interacting_bear/features/presentation/voice_input_widget.dart';
import 'package:interacting_bear/features/presentation/voice_output_cloud.dart';
import 'package:package_info_plus/package_info_plus.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _version = '';

  @override
  void initState() {
    super.initState();
    _getAppVersion();
  }

  Future<void> _getAppVersion() async {
    try {
      final PackageInfo packageInfo = await PackageInfo.fromPlatform();
      setState(() {
        _version = 'v${packageInfo.version}+${packageInfo.buildNumber}';
      });
    } catch (e) {
      setState(() {
        _version = 'v1.0.0+1'; // fallback version
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    print('home screen built');
    return Scaffold(
      body: Stack(
        children: [
          VoiceOutputCloud(
            child: BearAnimationWidget(),
          ),
          // Version display in bottom-left corner
          Positioned(
            bottom: 16,
            left: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _version,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Center(child: VoiceInputWidget()),
        ],
      ),
    );
  }
}
