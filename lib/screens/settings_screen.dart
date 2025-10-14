import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/theme_service.dart';
import '../providers/theme_provider.dart';
import '../screens/auth/auth_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';

class SettingsScreen extends StatefulWidget {
  final bool isSignedIn;
  
  const SettingsScreen({
    super.key,
    required this.isSignedIn,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final ThemeService _themeService = ThemeService();
  String _selectedLanguage = 'English';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final language = await _themeService.getLanguage();
    
    if (mounted) {
      setState(() {
        _selectedLanguage = language;
      });
    }
  }

  Future<void> _toggleTheme(bool value) async {
    await _themeService.setDarkMode(value);
    
    if (mounted) {
      Provider.of<ThemeProvider>(context, listen: false).setDarkMode(value);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(value ? 'Dark mode enabled' : 'Light mode enabled'),
          backgroundColor: const Color(0xFF2196F3),
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  Future<void> _changeLanguage() async {
    final isDarkMode = Provider.of<ThemeProvider>(context, listen: false).isDarkMode;
    final languages = ['English', 'Hindi', 'Tamil', 'Telugu', 'Bengali'];
    
    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: isDarkMode ? const Color(0xFF1A1A1A) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[700],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Select Language',
              style: TextStyle(
                color: isDarkMode ? Colors.white : Colors.black,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            ...languages.map((lang) => ListTile(
              title: Text(
                lang,
                style: TextStyle(
                  color: isDarkMode ? Colors.white : Colors.black,
                ),
              ),
              trailing: _selectedLanguage == lang
                  ? const Icon(Icons.check, color: Color(0xFF2196F3))
                  : null,
              onTap: () => Navigator.pop(context, lang),
            )),
          ],
        ),
      ),
    );

    if (selected != null && selected != _selectedLanguage) {
      setState(() => _selectedLanguage = selected);
      await _themeService.setLanguage(selected);
    }
  }

  Future<void> _shareApp() async {
    await Share.share(
      'Check out Newsify - Your personalized news app!\n\nDownload now:\nPlay Store: https://play.google.com/store/apps/details?id=com.newsify.app\nApp Store: https://apps.apple.com/app/newsify/id123456789',
      subject: 'Newsify - News at your fingertips',
    );
  }

  Future<void> _rateApp() async {
    final url = Uri.parse('https://play.google.com/store/apps/details?id=com.newsify.app');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _sendFeedback() async {
    final email = Uri(
      scheme: 'mailto',
      path: 'feedback@newsify.com',
      queryParameters: {
        'subject': 'Newsify App Feedback',
      },
    );
    
    if (await canLaunchUrl(email)) {
      await launchUrl(email);
    }
  }

  Future<void> _openTerms() async {
    final url = Uri.parse('https://newsify.com/terms');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.inAppBrowserView);
    }
  }

  Future<void> _openPrivacy() async {
    final url = Uri.parse('https://newsify.com/privacy');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.inAppBrowserView);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        final isDarkMode = themeProvider.isDarkMode;
        
        return Container(
          height: MediaQuery.of(context).size.height * 0.95,
          decoration: BoxDecoration(
            color: isDarkMode ? const Color(0xFF1A1A1A) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: isDarkMode ? Colors.grey[800]! : Colors.grey[300]!,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.arrow_back,
                        color: isDarkMode ? Colors.white : Colors.black,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Settings',
                      style: TextStyle(
                        color: isDarkMode ? Colors.white : Colors.black,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Sign In Banner (only if not signed in)
                      if (!widget.isSignedIn) _buildSignInBanner(isDarkMode),
                      
                      const SizedBox(height: 8),
                      
                      // Appearance Section
                      _buildSectionHeader('Appearance', isDarkMode),
                      _buildSwitchTile(
                        icon: Icons.dark_mode,
                        title: 'Night Mode',
                        subtitle: 'Enable dark theme',
                        value: isDarkMode,
                        onChanged: _toggleTheme,
                        isDarkMode: isDarkMode,
                      ),
                      _buildTile(
                        icon: Icons.language,
                        title: 'Language',
                        subtitle: _selectedLanguage,
                        onTap: _changeLanguage,
                        isDarkMode: isDarkMode,
                      ),

                      _buildDivider(isDarkMode),

                      // App Section
                      _buildSectionHeader('App', isDarkMode),
                      _buildTile(
                        icon: Icons.share,
                        title: 'Share App',
                        subtitle: 'Share with friends',
                        onTap: _shareApp,
                        isDarkMode: isDarkMode,
                      ),
                      _buildTile(
                        icon: Icons.star_rate,
                        title: 'Rate App',
                        subtitle: 'Rate us on app store',
                        onTap: _rateApp,
                        isDarkMode: isDarkMode,
                      ),
                      _buildTile(
                        icon: Icons.feedback,
                        title: 'Feedback',
                        subtitle: 'Send us your thoughts',
                        onTap: _sendFeedback,
                        isDarkMode: isDarkMode,
                      ),

                      _buildDivider(isDarkMode),

                      // Legal Section
                      _buildSectionHeader('Legal', isDarkMode),
                      _buildTile(
                        icon: Icons.description,
                        title: 'Terms & Conditions',
                        subtitle: 'Read our terms',
                        onTap: _openTerms,
                        isDarkMode: isDarkMode,
                      ),
                      _buildTile(
                        icon: Icons.privacy_tip,
                        title: 'Privacy Policy',
                        subtitle: 'Read our privacy policy',
                        onTap: _openPrivacy,
                        isDarkMode: isDarkMode,
                      ),

                      const SizedBox(height: 20),

                      // App Version
                      Center(
                        child: Text(
                          'Newsify v1.0.0',
                          style: TextStyle(
                            color: isDarkMode ? Colors.grey[600] : Colors.grey[500],
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSignInBanner(bool isDarkMode) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2196F3), Color(0xFF1976D2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.person_outline,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Sign In to Newsify',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Get personalized feed & save articles',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              AuthScreen.showAuthBottomSheet(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF2196F3),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: const Text(
              'Sign In',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      child: Text(
        title,
        style: TextStyle(
          color: isDarkMode ? Colors.grey[500] : Colors.grey[600],
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required bool isDarkMode,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF2196F3).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: const Color(0xFF2196F3),
                size: 22,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: isDarkMode ? Colors.white : Colors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: isDarkMode ? Colors.grey[500] : Colors.grey[600],
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: isDarkMode ? Colors.grey[600] : Colors.grey[400],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
    required bool isDarkMode,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF2196F3).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: const Color(0xFF2196F3),
              size: 22,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: isDarkMode ? Colors.white : Colors.black,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: isDarkMode ? Colors.grey[500] : Colors.grey[600],
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xFF2196F3),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider(bool isDarkMode) {
    return Divider(
      height: 1,
      thickness: 1,
      color: isDarkMode ? Colors.grey[900] : Colors.grey[200],
    );
  }
}