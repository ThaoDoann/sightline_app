import 'package:flutter/material.dart';
import 'app_bar.dart';
import 'footer.dart';

class MainLayout extends StatelessWidget {
  final Widget child;
  final bool showUserProfile;
  final bool showTTSVolume;
  
  const MainLayout({
    super.key,
    required this.child,
    this.showUserProfile = false,
    this.showTTSVolume = false,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonAppBar(showUserProfile: showUserProfile),
      body: child,
      bottomNavigationBar: CommonFooter(showTTSVolume: showTTSVolume),
    );
  }
}