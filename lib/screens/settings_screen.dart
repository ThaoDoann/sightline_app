import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../styles/app_theme.dart';
import '../main.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isDarkMode = false;
  double _ttsVolume = 0.5;
  double _fontSize = 16.0;
  bool _autoSave = true;
  bool _highQualityImages = true;
  String _ttsLanguage = 'en-US';
  
  final FlutterTts _flutterTts = FlutterTts();
  bool _isTestingVolume = false;
  
  static const String _volumePrefKey = 'tts_volume';
  static const String _themePrefKey = 'theme_mode';
  static const String _fontSizePrefKey = 'font_size';
  static const String _autoSavePrefKey = 'auto_save';
  static const String _highQualityPrefKey = 'high_quality_images';
  static const String _ttsLanguagePrefKey = 'tts_language';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    
    setState(() {
      // Load theme preference
      _isDarkMode = MyApp.themeNotifier.value == ThemeMode.dark;
      
      // Load all preferences
      _ttsVolume = prefs.getDouble(_volumePrefKey) ?? 0.5;
      _fontSize = prefs.getDouble(_fontSizePrefKey) ?? 16.0;
      _autoSave = prefs.getBool(_autoSavePrefKey) ?? true;
      _highQualityImages = prefs.getBool(_highQualityPrefKey) ?? true;
      _ttsLanguage = prefs.getString(_ttsLanguagePrefKey) ?? 'en-US';
    });
  }

  Future<void> _saveThemePreference(bool isDark) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themePrefKey, isDark ? 'dark' : 'light');
    
    // Update the theme notifier (keeping existing logic)
    MyApp.themeNotifier.value = isDark ? ThemeMode.dark : ThemeMode.light;
  }

  Future<void> _saveVolumePreference(double value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_volumePrefKey, value);
  }

  Future<void> _saveFontSizePreference(double value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_fontSizePrefKey, value);
  }

  Future<void> _saveAutoSavePreference(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_autoSavePrefKey, value);
  }

  Future<void> _saveHighQualityPreference(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_highQualityPrefKey, value);
  }

  Future<void> _saveTtsLanguagePreference(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_ttsLanguagePrefKey, value);
  }

  Future<void> _testVolume() async {
    if (_isTestingVolume) return;
    
    setState(() {
      _isTestingVolume = true;
    });

    try {
      await _flutterTts.stop();
      await _flutterTts.setVolume(_ttsVolume);
      await _flutterTts.setLanguage(_ttsLanguage);
      await _flutterTts.speak("This is a test of the text-to-speech volume at ${(_ttsVolume * 100).round()} percent.");
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error testing volume: $e')),
      );
    } finally {
      setState(() {
        _isTestingVolume = false;
      });
    }
  }

  @override
  void dispose() {
    _flutterTts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Settings',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.1),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Appearance Section
          _buildSectionHeader('Appearance'),
          _buildThemeSelector(),
          const SizedBox(height: 24),

          // Text & Display Section
          _buildSectionHeader('Text & Display'),
          _buildFontSizeControl(),
          const SizedBox(height: 24),

          // Accessibility Section
          _buildSectionHeader('Accessibility'),
          _buildVolumeControl(),
          const SizedBox(height: 12),
          _buildLanguageSelector(),
          const SizedBox(height: 24),

          // Image & Storage Section
          _buildSectionHeader('Image & Storage'),
          _buildImageQualityToggle(),
          const SizedBox(height: 12),
          _buildAutoSaveToggle(),
          const SizedBox(height: 24),

          // About Section
          _buildSectionHeader('About'),
          _buildAboutTile(),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppTheme.primaryColor,
        ),
      ),
    );
  }

  Widget _buildThemeSelector() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusM),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.palette_outlined,
                  color: AppTheme.primaryColor,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Theme',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        'Choose your preferred app theme',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildThemeOption(
                    'Light',
                    Icons.light_mode,
                    !_isDarkMode,
                    () => _toggleTheme(false),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildThemeOption(
                    'Dark',
                    Icons.dark_mode,
                    _isDarkMode,
                    () => _toggleTheme(true),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeOption(String label, IconData icon, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected 
              ? AppTheme.primaryColor.withOpacity(0.1)
              : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(AppTheme.borderRadiusS),
          border: Border.all(
            color: isSelected 
                ? AppTheme.primaryColor
                : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected 
                  ? AppTheme.primaryColor
                  : Colors.grey.shade600,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected 
                    ? AppTheme.primaryColor
                    : Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVolumeControl() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusM),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.volume_up,
                  color: AppTheme.primaryColor,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Text-to-Speech Volume',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        'Adjust volume for caption reading',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${(_ttsVolume * 100).round()}%',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: AppTheme.primaryColor,
                inactiveTrackColor: AppTheme.primaryColor.withOpacity(0.3),
                thumbColor: AppTheme.primaryColor,
                overlayColor: AppTheme.primaryColor.withOpacity(0.2),
                trackHeight: 4.0,
              ),
              child: Slider(
                value: _ttsVolume,
                min: 0.0,
                max: 1.0,
                divisions: 10,
                onChanged: (value) {
                  setState(() {
                    _ttsVolume = value;
                  });
                  _saveVolumePreference(value);
                },
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: ElevatedButton.icon(
                onPressed: _isTestingVolume ? null : _testVolume,
                icon: _isTestingVolume 
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.play_arrow),
                label: Text(
                  _isTestingVolume ? 'Testing...' : 'Test Volume',
                  style: GoogleFonts.poppins(fontSize: 14),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAboutTile() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusM),
      ),
      child: ListTile(
        leading: Icon(
          Icons.info_outline,
          color: AppTheme.primaryColor,
        ),
        title: Text(
          'About Sightline',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(
          'AI-powered image captioning app',
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: Colors.grey.shade400,
        ),
        onTap: () {
          _showAboutDialog();
        },
      ),
    );
  }

  void _toggleTheme(bool isDark) {
    setState(() {
      _isDarkMode = isDark;
    });
    _saveThemePreference(isDark);
  }

  Widget _buildFontSizeControl() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusM),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.font_download_outlined,
                  color: AppTheme.primaryColor,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Caption Font Size',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        'Adjust text size for better readability',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${_fontSize.round()}px',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: AppTheme.primaryColor,
                inactiveTrackColor: AppTheme.primaryColor.withOpacity(0.3),
                thumbColor: AppTheme.primaryColor,
                overlayColor: AppTheme.primaryColor.withOpacity(0.2),
                trackHeight: 4.0,
              ),
              child: Slider(
                value: _fontSize,
                min: 12.0,
                max: 24.0,
                divisions: 6,
                onChanged: (value) {
                  setState(() {
                    _fontSize = value;
                  });
                  _saveFontSizePreference(value);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageSelector() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusM),
      ),
      child: ListTile(
        leading: Icon(
          Icons.language,
          color: AppTheme.primaryColor,
        ),
        title: Text(
          'Speech Language',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(
          _ttsLanguage == 'en-US' ? 'English (US)' : _ttsLanguage,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: Colors.grey.shade400,
        ),
        onTap: () => _showLanguageDialog(),
      ),
    );
  }

  Widget _buildImageQualityToggle() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusM),
      ),
      child: SwitchListTile(
        secondary: Icon(
          Icons.high_quality,
          color: AppTheme.primaryColor,
        ),
        title: Text(
          'High Quality Images',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(
          'Use higher resolution for better AI analysis',
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
        value: _highQualityImages,
        activeColor: AppTheme.primaryColor,
        onChanged: (value) {
          setState(() {
            _highQualityImages = value;
          });
          _saveHighQualityPreference(value);
        },
      ),
    );
  }

  Widget _buildAutoSaveToggle() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusM),
      ),
      child: SwitchListTile(
        secondary: Icon(
          Icons.save_alt,
          color: AppTheme.primaryColor,
        ),
        title: Text(
          'Auto-save Captions',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(
          'Automatically save generated captions to history',
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
        value: _autoSave,
        activeColor: AppTheme.primaryColor,
        onChanged: (value) {
          setState(() {
            _autoSave = value;
          });
          _saveAutoSavePreference(value);
        },
      ),
    );
  }

  void _showLanguageDialog() {
    final languages = {
      'en-US': 'English (US)',
      'en-GB': 'English (UK)',
      'es-ES': 'Spanish',
      'fr-FR': 'French',
      'de-DE': 'German',
      'it-IT': 'Italian',
      'pt-BR': 'Portuguese',
      'ja-JP': 'Japanese',
      'zh-CN': 'Chinese',
    };

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Select Speech Language',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: languages.entries.map((entry) {
              return RadioListTile<String>(
                title: Text(entry.value),
                value: entry.key,
                groupValue: _ttsLanguage,
                activeColor: AppTheme.primaryColor,
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _ttsLanguage = value;
                    });
                    _saveTtsLanguagePreference(value);
                    Navigator.pop(context);
                  }
                },
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'About Sightline',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: Text(
          'Sightline is an AI-powered image captioning application that helps users understand and describe images through advanced machine learning technology.\n\n© 2025 Sightline\nDeveloped by Thao, Matthew, Navin & Chi',
          style: GoogleFonts.poppins(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Close',
              style: GoogleFonts.poppins(
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}