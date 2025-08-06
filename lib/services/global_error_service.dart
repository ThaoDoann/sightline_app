import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class GlobalErrorService {
  static GlobalKey<NavigatorState>? _navigatorKey;
  static OverlayEntry? _currentOverlay;

  // Initialize with the global navigator key
  static void initialize(GlobalKey<NavigatorState> navigatorKey) {
    _navigatorKey = navigatorKey;
  }

  static void showError(String message) {
    debugPrint('❌ GlobalError: $message');
    _showOverlay(message, isError: true);
  }

  static void showSuccess(String message) {
    debugPrint('✅ GlobalSuccess: $message');
    _showOverlay(message, isError: false);
  }

  static void _showOverlay(String message, {required bool isError}) {
    // Remove any existing overlay
    _currentOverlay?.remove();
    _currentOverlay = null;

    final context = _navigatorKey?.currentContext;
    if (context == null) {
      debugPrint('❌ GlobalError: No navigator context available');
      return;
    }

    try {
      // Get overlay directly without ancestor lookup
      final overlayState = _navigatorKey?.currentState?.overlay;
      if (overlayState == null) {
        debugPrint('❌ GlobalError: No overlay state available');
        return;
      }

      // Create the overlay entry
      _currentOverlay = OverlayEntry(
        builder: (context) => _MessageOverlay(
          message: message,
          isError: isError,
          onDismiss: () {
            _currentOverlay?.remove();
            _currentOverlay = null;
          },
        ),
      );

      // Insert the overlay
      overlayState.insert(_currentOverlay!);

      // Auto-dismiss after duration
      final duration = isError ? const Duration(seconds: 4) : const Duration(seconds: 3);
      Future.delayed(duration, () {
        _currentOverlay?.remove();
        _currentOverlay = null;
      });
      
    } catch (e) {
      debugPrint('❌ GlobalError: Failed to show overlay: $e');
      debugPrint('❌ GlobalError: Original message: $message');
    }
  }

  // Manually dismiss any current overlay
  static void dismiss() {
    _currentOverlay?.remove();
    _currentOverlay = null;
  }
}

class _MessageOverlay extends StatefulWidget {
  final String message;
  final bool isError;
  final VoidCallback onDismiss;

  const _MessageOverlay({
    required this.message,
    required this.isError,
    required this.onDismiss,
  });

  @override
  State<_MessageOverlay> createState() => _MessageOverlayState();
}

class _MessageOverlayState extends State<_MessageOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _slideAnimation = Tween<double>(
      begin: -100.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 16,
      left: 16,
      right: 16,
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, _slideAnimation.value),
            child: Opacity(
              opacity: _opacityAnimation.value,
              child: Material(
                color: Colors.transparent,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: widget.isError 
                        ? const Color(0xFFE53E3E) 
                        : const Color(0xFF38A169),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Icon(
                        widget.isError ? Icons.error_outline : Icons.check_circle_outline,
                        color: Colors.white,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          widget.message,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: widget.onDismiss,
                        child: Icon(
                          Icons.close,
                          color: Colors.white.withOpacity(0.8),
                          size: 20,
                        ),
                      ),
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
}