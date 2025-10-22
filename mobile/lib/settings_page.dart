import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_theme.dart';
import 'services/api_service.dart';
import 'utils/dialog_helper.dart';
import 'profile_page.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  // Settings state

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _showLogoutDialog() {
    DialogHelper.showLogoutConfirmation(
      context,
      onLogout: () async {
        try {
          await ApiService.logout();
          if (mounted) {
            Navigator.pushNamedAndRemoveUntil(
              context,
              '/',
              (route) => false,
            );
          }
        } catch (e) {
          if (mounted) {
            DialogHelper.showError(
              context,
              title: 'Logout Failed',
              message: 'Failed to logout. Please try again.',
            );
          }
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surfaceWhite,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Account Section
              _buildSectionHeader('Account'),
              const SizedBox(height: 16),
              _buildSettingsCard([
                _buildSettingsTile(
                  icon: Icons.person,
                  title: 'Profile',
                  subtitle: 'Manage your profile information',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ProfilePage(),
                      ),
                    );
                  },
                ),
              ]),

              const SizedBox(height: 24),

              // Support Section
              _buildSectionHeader('Support'),
              const SizedBox(height: 16),
              _buildSettingsCard([
                _buildSettingsTile(
                  icon: Icons.help,
                  title: 'Help & Support',
                  subtitle: 'Get help and contact support',
                  onTap: () {
                    DialogHelper.showInfo(
                      context,
                      title: 'Help & Support',
                      message: 'For support, please email us at scansuggest@gmail.com',
                    );
                  },
                ),
                _buildDivider(),
                _buildSettingsTile(
                  icon: Icons.info,
                  title: 'About',
                  subtitle: 'App version and information',
                  onTap: () {
                    DialogHelper.showInfo(
                      context,
                      title: 'About Scan2Suggest',
                      message: 'Version 1.0.0\n\nScan2Suggest - AI-powered recipe discovery app for Filipino cuisine.',
                    );
                  },
                ),
                
              
                
              
              ]),

              const SizedBox(height: 24),

              // Account Actions Section
              _buildSectionHeader('Account Actions'),
              const SizedBox(height: 16),
              _buildSettingsCard([
                _buildSettingsTile(
                  icon: Icons.logout,
                  title: 'Logout',
                  subtitle: 'Sign out of your account',
                  onTap: _showLogoutDialog,
                  textColor: Colors.red,
                  iconColor: Colors.red,
                ),
              ]),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: AppTheme.textPrimary,
      ),
    );
  }

  Widget _buildSettingsCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? textColor,
    Color? iconColor,
  }) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: (iconColor ?? AppTheme.primaryDarkGreen).withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          color: iconColor ?? AppTheme.primaryDarkGreen,
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: textColor ?? AppTheme.textPrimary,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 14,
          color: AppTheme.textSecondary,
        ),
      ),
      trailing: const Icon(
        Icons.chevron_right,
        color: AppTheme.textSecondary,
      ),
      onTap: onTap,
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      thickness: 1,
      color: Colors.grey.withOpacity(0.2),
      indent: 60,
    );
  }
}
