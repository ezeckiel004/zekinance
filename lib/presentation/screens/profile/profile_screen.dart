import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:local_auth/local_auth.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/localization/translations.dart';
import '../../providers/auth_provider.dart';
import '../../providers/settings_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider);
    final userName = user?.displayName ?? 'Marc Zekinance';
    final userEmail = user?.email ?? 'contact@zekinance.com';
    final userAvatar = user?.photoUrl;


    final titleColor = Theme.of(context).brightness == Brightness.dark 
        ? Colors.white 
        : AppColors.lightTextPrimary;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          context.tr(ref, 'profile_title'),
          style: TextStyle(color: titleColor, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            children: [
              // User Card with avatar and badge
              _buildUserCard(context, userName, userEmail, userAvatar),

              const SizedBox(height: 28),

              // Account & Preferences Section
              _buildPreferencesSection(context, ref),

              const SizedBox(height: 36),

              // Log Out Button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    ref.read(authStateProvider.notifier).logout();
                    context.go('/auth/login');
                  },
                  icon: const Icon(Icons.logout_rounded, color: AppColors.error),
                  label: Text(
                    context.tr(ref, 'logout'),
                    style: const TextStyle(color: AppColors.error, fontWeight: FontWeight.bold),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.error),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserCard(BuildContext context, String name, String email, String? avatarUrl) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color ?? (isDark ? AppColors.darkSurface : AppColors.lightSurface),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Theme.of(context).colorScheme.outline),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppColors.primaryGradient,
            ),
            child: CircleAvatar(
              radius: 36,
              backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
              backgroundColor: isDark ? AppColors.darkBg : AppColors.lightBg,
              child: avatarUrl == null 
                ? Icon(
                    Icons.person, 
                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary, 
                    size: 30,
                  )
                : null,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        style: TextStyle(
                          color: isDark ? Colors.white : AppColors.lightTextPrimary, 
                          fontWeight: FontWeight.bold, 
                          fontSize: 18,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Premium badge capsule
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        gradient: AppColors.goldGradient,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'PRO',
                        style: TextStyle(color: Colors.black, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  email,
                  style: TextStyle(
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary, 
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms);
  }

  Widget _buildPreferencesSection(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeMode = ref.watch(themeModeProvider);
    final biometricsActive = ref.watch(biometricsProvider);
    final user = ref.watch(authStateProvider);
    final userName = user?.displayName ?? 'Marc Zekinance';

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color ?? (isDark ? AppColors.darkSurface : AppColors.lightSurface),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Theme.of(context).colorScheme.outline),
      ),
      child: Column(
        children: [
          // Account Details Button
          _buildProfileTile(
            context: context,
            icon: Icons.person_outline_rounded,
            color: AppColors.accent,
            title: context.tr(ref, 'account_details'),
            subtitle: context.tr(ref, 'account_details_sub'),
            onTap: () => _showEditProfileSheet(context, ref, userName),
          ),
          
          _buildDivider(context),

          // Security & Biometrics Button
          _buildProfileTile(
            context: context,
            icon: Icons.security_rounded,
            color: AppColors.info,
            title: context.tr(ref, 'security_biometrics'),
            subtitle: biometricsActive 
                ? context.tr(ref, 'security_sub_on') 
                : context.tr(ref, 'security_sub_off'),
            trailing: Switch(
              value: biometricsActive,
              activeColor: AppColors.primary,
              onChanged: (val) => _toggleBiometrics(context, ref, biometricsActive),
            ),
            onTap: () => _toggleBiometrics(context, ref, biometricsActive),
          ),
          
          _buildDivider(context),

          // Language Selector Button
          _buildProfileTile(
            context: context,
            icon: Icons.language_rounded,
            color: AppColors.secondary,
            title: context.tr(ref, 'language'),
            subtitle: context.tr(ref, 'language_sub'),
            onTap: () => _showLanguageSheet(context, ref),
          ),
          
          _buildDivider(context),

          // Dark Theme Toggle Button
          _buildProfileTile(
            context: context,
            icon: Icons.palette_outlined,
            color: AppColors.primary,
            title: context.tr(ref, 'theme_title'),
            subtitle: themeMode == ThemeMode.dark 
                ? context.tr(ref, 'theme_dark_sub') 
                : context.tr(ref, 'theme_light_sub'),
            trailing: Switch(
              value: themeMode == ThemeMode.dark,
              activeColor: AppColors.primary,
              onChanged: (val) {
                ref.read(themeModeProvider.notifier).toggleTheme(val);
              },
            ),
            onTap: () {
              ref.read(themeModeProvider.notifier).toggleTheme(themeMode != ThemeMode.dark);
            },
          ),
          
          _buildDivider(context),

          // Notification Settings (DISABLED)
          Opacity(
            opacity: 0.4,
            child: _buildProfileTile(
              context: context,
              icon: Icons.notifications_none_rounded,
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              title: context.tr(ref, 'notifications'),
              subtitle: context.tr(ref, 'notifications_sub'),
              trailing: Icon(
                Icons.block_rounded, 
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary, 
                size: 16,
              ),
              onTap: () {}, // Tap handler left empty to disable it fully
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 150.ms);
  }

  Widget _buildProfileTile({
    required BuildContext context,
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    Widget? trailing,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(
        title, 
        style: TextStyle(
          color: isDark ? Colors.white : AppColors.lightTextPrimary, 
          fontWeight: FontWeight.bold, 
          fontSize: 15,
        ),
      ),
      subtitle: Text(
        subtitle, 
        style: TextStyle(
          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary, 
          fontSize: 11,
        ),
      ),
      trailing: trailing ?? Icon(
        Icons.arrow_forward_ios_rounded, 
        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary, 
        size: 14,
      ),
      onTap: onTap,
    );
  }

  Widget _buildDivider(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Divider(color: Theme.of(context).colorScheme.outline, height: 1),
    );
  }

  // --- ACTIONS & SHEETS ---

  Future<void> _toggleBiometrics(BuildContext context, WidgetRef ref, bool currentValue) async {
    final LocalAuthentication auth = LocalAuthentication();
    final lang = ref.read(languageProvider);
    
    try {
      final bool canCheck = await auth.canCheckBiometrics;
      final bool isSupported = await auth.isDeviceSupported();
      
      if (!context.mounted) return;
      if (!canCheck && !isSupported) {
        _showSnackBar(context, Translations.getText(lang, 'auth_not_available'), isError: true);
        return;
      }

      final bool authenticated = await auth.authenticate(
        localizedReason: Translations.getText(lang, 'auth_reason'),
        options: const AuthenticationOptions(
          biometricOnly: false, // Allows passcode, PIN, or pattern fallback ("securite du telephone")
          stickyAuth: true,
        ),
      );

      if (authenticated) {
        await ref.read(biometricsProvider.notifier).setBiometricsEnabled(!currentValue);
        if (!context.mounted) return;
        final msg = !currentValue
            ? (lang == 'fr' ? 'Sécurité biométrique activée' : 'Biometric security enabled')
            : (lang == 'fr' ? 'Sécurité biométrique désactivée' : 'Biometric security disabled');
        _showSnackBar(context, msg, isError: false);
      } else {
        if (!context.mounted) return;
        _showSnackBar(context, Translations.getText(lang, 'auth_failed'), isError: true);
      }
    } catch (e) {
      if (!context.mounted) return;
      _showSnackBar(context, '${Translations.getText(lang, 'auth_failed')}: $e', isError: true);
    }
  }

  void _showLanguageSheet(BuildContext context, WidgetRef ref) {
    final currentLang = ref.watch(languageProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sheetBg = Theme.of(context).cardTheme.color ?? (isDark ? AppColors.darkSurface : AppColors.lightSurface);
    final textColor = isDark ? Colors.white : AppColors.lightTextPrimary;

    showModalBottomSheet(
      context: context,
      backgroundColor: sheetBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      currentLang == 'fr' ? 'Choisir la langue' : 'Choose Language',
                      style: TextStyle(
                        color: textColor,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(
                        Icons.close_rounded, 
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Text('🇫🇷', style: TextStyle(fontSize: 24)),
                  title: Text(
                    'Français',
                    style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
                  ),
                  trailing: currentLang == 'fr'
                      ? const Icon(Icons.check_circle_rounded, color: AppColors.primary)
                      : null,
                  onTap: () {
                    ref.read(languageProvider.notifier).setLanguage('fr');
                    Navigator.pop(context);
                  },
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Divider(color: Theme.of(context).colorScheme.outline, height: 1),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Text('🇬🇧', style: TextStyle(fontSize: 24)),
                  title: Text(
                    'English',
                    style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
                  ),
                  trailing: currentLang == 'en'
                      ? const Icon(Icons.check_circle_rounded, color: AppColors.primary)
                      : null,
                  onTap: () {
                    ref.read(languageProvider.notifier).setLanguage('en');
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showEditProfileSheet(BuildContext context, WidgetRef ref, String currentName) {
    final currentLang = ref.read(languageProvider);
    final nameController = TextEditingController(text: currentName);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sheetBg = Theme.of(context).cardTheme.color ?? (isDark ? AppColors.darkSurface : AppColors.lightSurface);
    final textColor = isDark ? Colors.white : AppColors.lightTextPrimary;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: sheetBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    Translations.getText(currentLang, 'edit_profile'),
                    style: TextStyle(
                      color: textColor,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(
                      Icons.close_rounded, 
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                Translations.getText(currentLang, 'full_name').toUpperCase(),
                style: TextStyle(
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: nameController,
                style: TextStyle(color: textColor),
                decoration: InputDecoration(
                  hintText: currentLang == 'fr' ? 'Ex: Marc Zekinance' : 'e.g. Marc Zekinance',
                  hintStyle: TextStyle(
                    color: (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary).withOpacity(0.5),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
                autofocus: true,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Theme.of(context).colorScheme.outline),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        Translations.getText(currentLang, 'cancel'),
                        style: TextStyle(color: textColor),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        final newName = nameController.text.trim();
                        if (newName.isNotEmpty) {
                          try {
                            await ref.read(authStateProvider.notifier).updateDisplayName(newName);
                            if (!context.mounted) return;
                            Navigator.pop(context);
                            _showSnackBar(
                              context, 
                              currentLang == 'fr' ? 'Profil mis à jour' : 'Profile updated',
                              isError: false,
                            );
                          } catch (e) {
                            if (!context.mounted) return;
                            _showSnackBar(context, 'Error: $e', isError: true);
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        Translations.getText(currentLang, 'save'),
                        style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _showSnackBar(BuildContext context, String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: isError ? AppColors.error : AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
