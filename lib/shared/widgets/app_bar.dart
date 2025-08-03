import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../services/auth_services.dart';
import '../../services/caption_service.dart';
import '../../styles/app_theme.dart';
import '../../main.dart';
import '../../screens/login_screen.dart';
import '../../screens/settings_screen.dart';
import 'profile_menu.dart';

class CommonAppBar extends StatefulWidget implements PreferredSizeWidget {
  final bool showUserProfile;
  
  const CommonAppBar({
    super.key,
    this.showUserProfile = false,
  });

  @override
  State<CommonAppBar> createState() => _CommonAppBarState();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 1);
}

class _CommonAppBarState extends State<CommonAppBar> {
  bool _isProfileMenuOpen = false;
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;

  @override
  void dispose() {
    _removeOverlay();
    super.dispose();
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    if (mounted) {
      setState(() {
        _isProfileMenuOpen = false;
      });
    } else {
      _isProfileMenuOpen = false;
    }
  }

  void _showProfileMenu() {
    if (_isProfileMenuOpen) {
      _removeOverlay();
    } else {
      _overlayEntry = _createOverlayEntry();
      Overlay.of(context).insert(_overlayEntry!);
      if (mounted) {
        setState(() {
          _isProfileMenuOpen = true;
        });
      }
    }
  }

  OverlayEntry _createOverlayEntry() {
    final user = context.read<AuthService>();
    return OverlayEntry(
      builder: (overlayContext) => Positioned(
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
                if (mounted) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SettingsScreen()),
                  );
                }
              },
              onLogoutTap: () async {
                _removeOverlay();
                if (mounted) {
                  // Clear caption data before logout
                  context.read<CaptionService>().clearAllData();
                  await context.read<AuthService>().logout();
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  );
                }
              },
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(
        'Sightline',
        style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
      ),
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
        // Show user profile only when logged in
        if (widget.showUserProfile) ...[
          CompositedTransformTarget(
            link: _layerLink,
            child: Consumer<AuthService>(
              builder: (context, auth, child) {
                return Row(
                  children: [
                    Text(
                      auth.username ?? 'username',
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
                );
              },
            ),
          ),
        ],
        const SizedBox(width: 16),
      ],
    );
  }
}