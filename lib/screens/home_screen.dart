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
import '../services/global_error_service.dart';
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
        
        try {
          if (kIsWeb) {
            // Generate caption and save to database in one step
            await context.read<CaptionService>().generateCaptionWeb(bytes);
          } else {
            // Generate caption and save to database in one step
            await context.read<CaptionService>().generateCaption(
              File(pickedFile.path),
            );
          }
        } catch (captionError) {
          // Handle backend errors from caption service
          debugPrint('❌ Caption generation error: $captionError');
          
          // Clear the selected image on error
          setState(() {
            _imageBytes = null;
          });
          
          // Check if it's a backend validation error (400 status)
          if (captionError.toString().contains('Invalid file extension') ||
              captionError.toString().contains('Only .jpg, .jpeg, and .png files are allowed') ||
              captionError.toString().contains('cannot identify image file')) {
            GlobalErrorService.showError(
              'Invalid image format. Only JPG, JPEG, and PNG files are supported.',
            );
          } else if (captionError.toString().contains('ClientException') ||
                     captionError.toString().contains('Failed to fetch')) {
            GlobalErrorService.showError(
              'Unable to connect to server. Please check your internet connection.',
            );
          } else {
            GlobalErrorService.showError(
              'Failed to generate caption. Please try again.',
            );
          }
        }
      }
    } catch (e) {
      debugPrint('❌ Image picker error: $e');
      GlobalErrorService.showError('Failed to select image. Please try again.');
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

  Future<void> _clearHistory() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Clear History',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: Text(
          'Are you sure you want to clear all caption history? This action cannot be undone.',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(color: Colors.grey.shade600),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(
              'Clear',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await context.read<CaptionService>().clearCaptionHistory();
      GlobalErrorService.showSuccess('History cleared successfully');
    }
  }

  void _showImageUploadOptions() {
    if (kIsWeb) {
      // For web, directly pick image
      _pickImage(ImageSource.gallery);
    } else {
      // For mobile, show options
      showModalBottomSheet(
        context: context,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (context) => Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Select Image Source',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        Navigator.pop(context);
                        _pickImage(ImageSource.camera);
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            Icon(Icons.camera_alt, size: 32, color: AppTheme.primaryColor),
                            const SizedBox(height: 8),
                            Text(
                              'Camera',
                              style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        Navigator.pop(context);
                        _pickImage(ImageSource.gallery);
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            Icon(Icons.photo_library, size: 32, color: AppTheme.primaryColor),
                            const SizedBox(height: 8),
                            Text(
                              'Gallery',
                              style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isLargeScreen = screenSize.width > 768;
    final isTablet = screenSize.width > 600 && screenSize.width <= 768;
    final maxWidth = isLargeScreen ? 1200.0 : double.infinity;

    return MainLayout(
      showUserProfile: true,
      showTTSVolume: false,
      child: Consumer<CaptionService>(
        builder: (context, captionService, child) {
          return SingleChildScrollView(
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxWidth),
                child: Padding(
                  padding: EdgeInsets.all(isLargeScreen ? 32.0 : 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Section
                      _buildHeaderSection(context, isLargeScreen),
                      const SizedBox(height: 32),

                      // Upload Section (includes image preview when image is selected)
                      _buildUploadSection(context, captionService, isLargeScreen),

                      // Caption Result Section
                      if (!captionService.isLoading && captionService.caption != null) ...[
                        const SizedBox(height: 32),
                        _buildCaptionResultSection(context, captionService, isLargeScreen),
                      ],

                      const SizedBox(height: 48),
                      
                      // History Section
                      _buildHistorySection(context, captionService, isLargeScreen),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeaderSection(BuildContext context, bool isLargeScreen) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'AI Image Captioning',
          style: GoogleFonts.poppins(
            fontSize: isLargeScreen ? 32 : 24,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryColor,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Upload an image and get an AI-powered description in seconds',
          style: GoogleFonts.poppins(
            fontSize: isLargeScreen ? 16 : 14,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildUploadSection(BuildContext context, CaptionService captionService, bool isLargeScreen) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Show image preview if image is selected, otherwise show upload icon and text
            if (_imageBytes != null) ...[
              // Image preview section
              Container(
                width: double.infinity,
                height: isLargeScreen ? 400.0 : 300.0,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.grey.shade100,
                ),
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.memory(
                        _imageBytes!,
                        fit: BoxFit.contain,
                        width: double.infinity,
                        height: double.infinity,
                      ),
                    ),
                    // Remove image button
                    if (!captionService.isLoading)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: IconButton(
                            onPressed: () => setState(() => _imageBytes = null),
                            icon: const Icon(Icons.close, color: Colors.white, size: 20),
                            tooltip: 'Remove image',
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              if (captionService.isLoading) ...[
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      CircularProgressIndicator(color: AppTheme.primaryColor),
                      const SizedBox(height: 12),
                      Text(
                        'Analyzing image and generating caption...',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ] else ...[
              // Upload icon and text (shown when no image is selected)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  kIsWeb ? Icons.upload_file : Icons.add_photo_alternate,
                  size: isLargeScreen ? 48 : 40,
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                kIsWeb ? 'Click to upload an image' : 'Take a photo or choose from gallery',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade700,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Select your image file - supported formats will be validated',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.grey.shade500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 20),
            // Upload button (always visible)
            SizedBox(
              width: isLargeScreen ? 200 : double.infinity,
              child: ElevatedButton.icon(
                onPressed: captionService.isLoading ? null : _showImageUploadOptions,
                icon: Icon(kIsWeb ? Icons.upload_file : Icons.add_photo_alternate),
                label: Text(
                  _imageBytes != null 
                    ? (kIsWeb ? 'Change Image' : 'Change Photo')
                    : (kIsWeb ? 'Upload Image' : 'Add Image'),
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCaptionResultSection(BuildContext context, CaptionService captionService, bool isLargeScreen) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.auto_awesome, color: AppTheme.primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Generated Caption',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface.withOpacity(0.7),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                ),
              ),
              child: Consumer<FontSizeService>(
                builder: (context, fontSizeService, child) {
                  return Text(
                    captionService.caption!,
                    style: GoogleFonts.poppins(
                      fontSize: fontSizeService.fontSize,
                      fontWeight: FontWeight.w500,
                      height: 1.5,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                onPressed: () => _speakCaption(captionService.caption!),
                icon: Icon(Icons.volume_up, size: 18),
                label: Text(
                  'Speak Caption',
                  style: GoogleFonts.poppins(fontSize: 14),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                  foregroundColor: AppTheme.primaryColor,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistorySection(BuildContext context, CaptionService captionService, bool isLargeScreen) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'History',
              style: GoogleFonts.poppins(
                fontSize: isLargeScreen ? 24 : 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            if (captionService.history.isNotEmpty)
              TextButton.icon(
                onPressed: _clearHistory,
                icon: Icon(Icons.clear_all, size: 16, color: Colors.red),
                label: Text(
                  'Clear All',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.red,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        
        // Show loading spinner only when history is empty
        if (captionService.history.isEmpty) ...[
          if (captionService.isLoading || captionService.isHistoryLoading)
            _buildLoadingCard('Loading history...')
          else
            _buildEmptyHistoryCard(),
        ] else ...[
          // History items (updates silently when not empty)
          ...captionService.history.asMap().entries.map(
            (entry) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _buildHistoryItem(entry.value, entry.key),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildLoadingCard(String message) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            CircularProgressIndicator(color: AppTheme.primaryColor),
            const SizedBox(height: 16),
            Text(
              message,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyHistoryCard() {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(
              Icons.history,
              size: 48,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'No captions yet',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Upload an image to get started!',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryItem(CaptionEntry entry, int index) {
    final isExpanded = _expandedItems[index] ?? false;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _toggleHistoryItem(index),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: entry.imageBytes != null
                      ? Image.memory(
                          entry.imageBytes!,
                          width: isExpanded ? 200 : 80,
                          height: isExpanded ? 200 : 80,
                          fit: BoxFit.cover,
                        )
                      : Container(
                          width: 80,
                          height: 80,
                          color: Colors.grey.shade200,
                          child: Icon(
                            Icons.image_not_supported,
                            color: Colors.grey.shade400,
                          ),
                        ),
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
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            DateFormat('MMM d, y • h:mm a').format(entry.timestamp),
                            style: GoogleFonts.poppins(
                              fontSize: 11,
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
                                size: 28,
                              ),
                              onPressed: () => _speakCaption(entry.caption),
                              tooltip: 'Speak Caption',
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              isExpanded ? Icons.expand_less : Icons.expand_more,
                              color: Colors.grey.shade600,
                              size: 18,
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12.0),
                    Consumer<FontSizeService>(
                      builder: (context, fontSizeService, child) {
                        return Text(
                          entry.caption,
                          style: GoogleFonts.poppins(
                            fontSize: fontSizeService.fontSize * 0.875,
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
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
