import 'package:flutter/material.dart';
import '../../styles/app_theme.dart';

class ProfileMenu extends StatelessWidget {
  final String userName;
  final String userEmail;
  final VoidCallback onSettingsTap;
  final VoidCallback onLogoutTap;

  const ProfileMenu({
    super.key,
    required this.userName,
    required this.userEmail,
    required this.onSettingsTap,
    required this.onLogoutTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusM),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(AppTheme.spacingM),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(AppTheme.borderRadiusM),
                topRight: Radius.circular(AppTheme.borderRadiusM),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(userName, style: AppTheme.titleMedium),
                const SizedBox(height: AppTheme.spacingXS),
                Text(userEmail, style: AppTheme.bodySmall),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.settings, color: AppTheme.primaryColor),
            title: Text('Account Settings', style: AppTheme.bodyMedium),
            onTap: onSettingsTap,
          ),
          ListTile(
            leading: const Icon(Icons.logout, color: AppTheme.errorColor),
            title: Text(
              'Logout',
              style: AppTheme.bodyMedium.copyWith(color: AppTheme.errorColor),
            ),
            onTap: onLogoutTap,
          ),
        ],
      ),
    );
  }
}
