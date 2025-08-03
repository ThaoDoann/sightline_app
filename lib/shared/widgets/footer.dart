import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../styles/app_theme.dart';

class CommonFooter extends StatefulWidget {
  final bool showTTSVolume;
  
  const CommonFooter({
    super.key,
    this.showTTSVolume = false,
  });

  @override
  State<CommonFooter> createState() => _CommonFooterState();
  
  static _CommonFooterState? of(BuildContext context) {
    return context.findAncestorStateOfType<_CommonFooterState>();
  }
}

class _CommonFooterState extends State<CommonFooter> {
  double _ttsVolume = 0.5;
  static const String _volumePrefKey = 'tts_volume';

  double get ttsVolume => _ttsVolume;

  @override
  void initState() {
    super.initState();
    _loadVolumePreference();
  }

  Future<void> _loadVolumePreference() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _ttsVolume = prefs.getDouble(_volumePrefKey) ?? 0.5;
    });
  }

  Future<void> _saveVolumePreference(double value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_volumePrefKey, value);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 6,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.showTTSVolume) ...[
              Text(
                'TTS Volume',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
              Slider(
                value: _ttsVolume,
                min: 0.0,
                max: 1.0,
                divisions: 10,
                label: '${(_ttsVolume * 100).round()}%',
                onChanged: (value) {
                  setState(() {
                    _ttsVolume = value;
                  });
                  _saveVolumePreference(value);
                },
                activeColor: AppTheme.primaryColor,
                inactiveColor: AppTheme.primaryColor.withOpacity(0.3),
              ),
              const SizedBox(height: 8),
            ],
            Center(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  '© 2025 Sightline • Powered by Flutter Develop By Thao, Matthew, Navin & Chi',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.6),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}