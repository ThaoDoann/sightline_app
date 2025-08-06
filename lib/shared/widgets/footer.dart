import 'package:flutter/material.dart';
import '../../styles/app_theme.dart';

class CommonFooter extends StatelessWidget {
  final bool showTTSVolume; // Kept for compatibility but not used
  
  const CommonFooter({
    super.key,
    this.showTTSVolume = false,
  });

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