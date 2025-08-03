import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_bootstrap/flutter_bootstrap.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/caption_service.dart';
import '../models/caption_entry.dart';
import '../shared/widgets/profile_menu.dart';
import '../styles/app_theme.dart';
import 'dart:convert';
import '../styles/app_theme.dart';
import 'login_screen.dart';
import '../services/auth_services.dart';
import '../main.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Uint8List? _imageBytes;
  final FlutterTts _flutterTts = FlutterTts();
  final ImagePicker _picker = ImagePicker();
  final Map<int, bool> _expandedItems = {};
  bool _isProfileMenuOpen = false;
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  
  double _ttsVolume = 0.5; // Default Volume
  static const String _volumePrefKey = 'tts_volume';

  @override
  void initState() {
    super.initState();
    _loadVolumePreference();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final auth = context.read<AuthService>();
      if (auth.token == null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
        return;
      }
      await context.read<CaptionService>().fetchHistoryFromBackend();
    });
  }

  @override
  void dispose() {
    _removeOverlay();
    super.dispose();
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    setState(() {
      _isProfileMenuOpen = false;
    });
  }

  void _showProfileMenu() {
    if (_isProfileMenuOpen) {
      _removeOverlay();
    } else {
      _overlayEntry = _createOverlayEntry();
      Overlay.of(context).insert(_overlayEntry!);
      setState(() {
        _isProfileMenuOpen = true;
      });
    }
  }

  OverlayEntry _createOverlayEntry() {
    final user = context.read<AuthService>();
    return OverlayEntry(
      builder: (context) => Positioned(
        width: 250,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: const Offset(-50, 60),
          child: Material(
            elevation: 8.0,
            borderRadius: BorderRadius.circular(AppTheme.borderRadiusM),
            child: ProfileMenu(
              userName: user?.username ?? 'User',
              userEmail: user?.email ?? 'email@example.com',
              onSettingsTap: () {
                _removeOverlay();
              },
              onLogoutTap: () async {
                _removeOverlay();
                // Clear caption data before logout
                context.read<CaptionService>().clearAllData();
                await context.read<AuthService>().logout();
                if (!mounted) return;
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

    Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(source: source);
      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          _imageBytes = bytes;
        });

        if (kIsWeb) {
          // Generate caption and save to database in one step
          await context.read<CaptionService>().generateCaptionWeb(bytes);
        } else {
          // Generate caption and save to database in one step
          await context.read<CaptionService>().generateCaption(
            File(pickedFile.path),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error picking image: $e')));
    }
  }

  Future<void> _speakCaption(String caption) async {
    await _flutterTts.stop();
    await _flutterTts.setVolume(_ttsVolume);
	await _flutterTts.speak(caption);
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
  
  // @override
  // void initState() {
  //   super.initState();
  //   _loadVolumePreference();
  // }

  void _toggleHistoryItem(int index) {
    setState(() {
      _expandedItems[index] = !(_expandedItems[index] ?? false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthService>();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Sightline',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        // backgroundColor: Colors.white,
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.1),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.primaryColor.withOpacity(0.3),
                  AppTheme.primaryColor,
                  AppTheme.primaryColor.withOpacity(0.3),
                ],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
            ),
          ),
        ),
        actions: [
          Row(
            children: [
                Icon(Icons.light_mode),
                Switch(
                  value: MyApp.themeNotifier.value == ThemeMode.dark,
                  onChanged: (value) {
                    setState(() {
                      MyApp.themeNotifier.value =
                          value ? ThemeMode.dark : ThemeMode.light;
                    });
                  },
                ),
                Icon(Icons.dark_mode),
                SizedBox(width: 16),
              ],
          ),

          CompositedTransformTarget(
            link: _layerLink,
            child: Row(
              children: [
                Text(
                  user.username ?? 'username',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: CircleAvatar(
                    backgroundColor: _isProfileMenuOpen
                        ? AppTheme.primaryColor
                        : Colors.blue,
                    child: const Icon(Icons.person, color: Colors.white),
                  ),
                  onPressed: _showProfileMenu,
                  tooltip: 'User Profile',
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Consumer<CaptionService>(
        builder: (context, captionService, child) {
          return SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: () => _pickImage(ImageSource.gallery),
                  icon: const Icon(Icons.upload_file),
                  label: const Text("Upload Image"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                if (_imageBytes != null) ...[
                  Image.memory(_imageBytes!, height: 200, fit: BoxFit.cover),
                  const SizedBox(height: 20),
                  
                  // Loading indicator while generating caption
                  if (captionService.isLoading)
                    const Padding(
                      padding: EdgeInsets.all(20.0),
                      child: Column(
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 10),
                          Text(
                            'Generating caption...',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  
                  // Caption display when not loading and caption exists
                  if (!captionService.isLoading && captionService.caption != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Column(
                        children: [
                          const SizedBox(height: 10),
                          Text(
                            captionService.caption!,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.volume_up),
                            onPressed: () =>
                                _speakCaption(captionService.caption!),
                            tooltip: 'Speak Caption',
                          ),
                        ],
                      ),
                    ),
                ],

                const SizedBox(height: 20),
                Text(
                  'Caption History',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 10),
                
                // Show loading indicator for history
                if (captionService.isLoading && captionService.history.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(20.0),
                    child: Column(
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 10),
                        Text(
                          'Loading history...',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                
                // Show history items when not loading or when history exists
                if (!captionService.isLoading || captionService.history.isNotEmpty)
                  if (captionService.history.isNotEmpty)
                    ...captionService.history.asMap().entries.map(
                      (entry) => _buildHistoryItem(entry.value, entry.key),
                    )
                  else
                    const Padding(
                      padding: EdgeInsets.all(20.0),
                      child: Text(
                        'No captions yet. Upload an image to get started!',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
              ],
            ),
          );
        },
      ),
	  bottomNavigationBar: SafeArea(
	    child: Container(
		  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
		  decoration: BoxDecoration(
		    color: Colors.white,
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
        Center(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              '© 2025 Sightline • Powered by Flutter Develop By Thao, Matthew, Navin & CHI',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: Colors.black.withOpacity(0.6),
              ),
            ),
            ),
        ),
		    ],
		  ),
      
	    ),
	  ),
    );
  }

  Widget _buildHistoryItem(CaptionEntry entry, int index) {
    final isExpanded = _expandedItems[index] ?? false;

    return Container(
      margin: const EdgeInsets.only(bottom: 16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusL),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _toggleHistoryItem(index),
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusL),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppTheme.borderRadiusM),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppTheme.borderRadiusM),
                  child: entry.imageBytes != null
                      ? Image.memory(
                          entry.imageBytes!,
                          width: isExpanded ? 200 : 80,
                          height: isExpanded ? 200 : 80,
                          fit: BoxFit.cover,
                        )
                      : const Icon(Icons.image_not_supported),
                ),
              ),
              const SizedBox(width: 16.0),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(
                              AppTheme.borderRadiusS,
                            ),
                          ),
                          child: Text(
                            DateFormat(
                              'MMM d, y • h:mm a',
                            ).format(entry.timestamp),
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Row(
                          children: [
                            IconButton(
                              icon: Icon(
                                Icons.volume_up,
                                color: AppTheme.primaryColor,
                                size: 20,
                              ),
                              onPressed: () => _speakCaption(entry.caption),
                              tooltip: 'Speak Caption',
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              isExpanded
                                  ? Icons.expand_less
                                  : Icons.expand_more,
                              color: AppTheme.textSecondaryColor,
                              size: 20,
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 8.0),
                    Text(
                      entry.caption,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: const Color.fromARGB(255, 17, 17, 17),
                        height: 1.4,
                      ),
                      maxLines: isExpanded ? null : 2,
                      overflow: isExpanded ? null : TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
