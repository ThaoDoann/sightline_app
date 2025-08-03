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
import '../shared/widgets/main_layout.dart';
import '../styles/app_theme.dart';
import 'dart:convert';
import '../styles/app_theme.dart';
import 'login_screen.dart';
import '../services/auth_services.dart';
import '../services/font_size_service.dart';
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
  


  @override
  void initState() {
    super.initState();
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
    // Get volume from shared preferences directly
    final prefs = await SharedPreferences.getInstance();
    final volume = prefs.getDouble('tts_volume') ?? 0.5;
    await _flutterTts.setVolume(volume);
    await _flutterTts.speak(caption);
  }

  void _toggleHistoryItem(int index) {
    setState(() {
      _expandedItems[index] = !(_expandedItems[index] ?? false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      showUserProfile: true,
      showTTSVolume: false, // Volume control moved to settings
      child: Consumer<CaptionService>(
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
                          Consumer<FontSizeService>(
                            builder: (context, fontSizeService, child) {
                              return Text(
                                captionService.caption!,
                                style: TextStyle(
                                  fontSize: fontSizeService.fontSize,
                                  fontWeight: FontWeight.w500,
                                ),
                              );
                            },
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
                    Consumer<FontSizeService>(
                      builder: (context, fontSizeService, child) {
                        return Text(
                          entry.caption,
                          style: GoogleFonts.poppins(
                            fontSize: fontSizeService.fontSize * 0.875, // Slightly smaller for history
                            color: const Color.fromARGB(255, 17, 17, 17),
                            height: 1.4,
                          ),
                          maxLines: isExpanded ? null : 2,
                          overflow: isExpanded ? null : TextOverflow.ellipsis,
                        );
                      },
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
