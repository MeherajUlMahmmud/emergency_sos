import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/error_widgets.dart';
import '../../services/auth_service.dart';
import '../emergency/emergency_contacts_screen.dart';
import '../emergency/emergency_history_screen.dart';
import '../auth/login_screen.dart';

class SettingsScreen extends StatelessWidget {
  static const String routeName = '/settings';

  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildSection(
                title: 'Appearance',
                children: [
                  _buildThemeSelector(context, themeProvider),
                  const SizedBox(height: 16),
                  _buildAccessibilitySettings(context, themeProvider),
                ],
              ),
              const SizedBox(height: 24),
              _buildSection(
                title: 'Emergency Settings',
                children: [
                  _buildEmergencySettings(context),
                ],
              ),
              const SizedBox(height: 24),
              _buildSection(
                title: 'About',
                children: [
                  _buildAboutSection(context),
                ],
              ),
              const SizedBox(height: 24),
              _buildSection(
                title: 'Account',
                children: [
                  _buildAccountSection(context),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: children,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildThemeSelector(
      BuildContext context, ThemeProvider themeProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Theme',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildThemeOption(
                context,
                'Light',
                Icons.light_mode,
                themeProvider.themeMode == ThemeMode.light,
                () => themeProvider.setThemeMode(ThemeMode.light),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildThemeOption(
                context,
                'Dark',
                Icons.dark_mode,
                themeProvider.themeMode == ThemeMode.dark,
                () => themeProvider.setThemeMode(ThemeMode.dark),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildThemeOption(
                context,
                'System',
                Icons.settings_system_daydream,
                themeProvider.themeMode == ThemeMode.system,
                () => themeProvider.setThemeMode(ThemeMode.system),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildThemeOption(
    BuildContext context,
    String label,
    IconData icon,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryRed.withOpacity(0.1) : null,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppTheme.primaryRed : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? AppTheme.primaryRed : Colors.grey.shade600,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? AppTheme.primaryRed : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccessibilitySettings(
      BuildContext context, ThemeProvider themeProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Accessibility',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        _buildSwitchTile(
          context,
          'Large Text',
          'Increase text size for better readability',
          Icons.text_fields,
          themeProvider.isLargeText,
          (value) => themeProvider.setLargeText(value),
        ),
        _buildSwitchTile(
          context,
          'High Contrast',
          'Increase contrast for better visibility',
          Icons.contrast,
          themeProvider.isHighContrast,
          (value) => themeProvider.setHighContrast(value),
        ),
        _buildSwitchTile(
          context,
          'Voice Commands',
          'Enable voice command support',
          Icons.mic,
          themeProvider.isVoiceEnabled,
          (value) => themeProvider.setVoiceEnabled(value),
        ),
      ],
    );
  }

  Widget _buildSwitchTile(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.primaryRed),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: AppTheme.primaryRed,
      ),
    );
  }

  Widget _buildEmergencySettings(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Emergency Preferences',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        ListTile(
          leading: const Icon(Icons.phone, color: AppTheme.primaryRed),
          title: const Text('Emergency Contacts'),
          subtitle: const Text('Manage your emergency contacts'),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: () {
            Navigator.pushNamed(context, EmergencyContactsScreen.routeName);
          },
        ),
        ListTile(
          leading: const Icon(Icons.location_on, color: AppTheme.primaryRed),
          title: const Text('Location Settings'),
          subtitle: const Text('Configure location sharing preferences'),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: () {
            Navigator.pushNamed(context, EmergencyHistoryScreen.routeName);
          },
        ),
        ListTile(
          leading: const Icon(Icons.notifications, color: AppTheme.primaryRed),
          title: const Text('Notification Settings'),
          subtitle: const Text('Configure emergency notifications'),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: () {
            // TODO: Navigate to notification settings screen
            ErrorWidgets.snackBarError(
              context: context,
              message: 'Notification settings feature coming soon!',
            );
          },
        ),
      ],
    );
  }

  Widget _buildAboutSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'App Information',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        ListTile(
          leading: const Icon(Icons.info, color: AppTheme.primaryRed),
          title: const Text('Version'),
          subtitle: const Text('1.0.0'),
        ),
        ListTile(
          leading: const Icon(Icons.privacy_tip, color: AppTheme.primaryRed),
          title: const Text('Privacy Policy'),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: () {
            // TODO: Show privacy policy
            ErrorWidgets.snackBarError(
              context: context,
              message: 'Privacy policy feature coming soon!',
            );
          },
        ),
        ListTile(
          leading: const Icon(Icons.description, color: AppTheme.primaryRed),
          title: const Text('Terms of Service'),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: () {
            // TODO: Show terms of service
            ErrorWidgets.snackBarError(
              context: context,
              message: 'Terms of service feature coming soon!',
            );
          },
        ),
        ListTile(
          leading: const Icon(Icons.feedback, color: AppTheme.primaryRed),
          title: const Text('Send Feedback'),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: () {
            // TODO: Open feedback form
            ErrorWidgets.snackBarError(
              context: context,
              message: 'Feedback feature coming soon!',
            );
          },
        ),
      ],
    );
  }

  Widget _buildAccountSection(BuildContext context) {
    final AuthService authService = AuthService();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Account Management',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        ListTile(
          leading: const Icon(Icons.logout, color: AppTheme.primaryRed),
          title: const Text('Sign Out'),
          subtitle: const Text('Sign out of your account'),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: () async {
            // Show confirmation dialog
            final shouldSignOut = await showDialog<bool>(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: const Text('Sign Out'),
                  content: const Text('Are you sure you want to sign out?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: const Text('Sign Out'),
                    ),
                  ],
                );
              },
            );

            if (shouldSignOut == true) {
              await authService.signOut();
              if (context.mounted) {
                Navigator.of(context).pushNamedAndRemoveUntil(
                  LoginScreen.routeName,
                  (route) => false,
                );
              }
            }
          },
        ),
      ],
    );
  }
}
