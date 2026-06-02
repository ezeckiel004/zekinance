import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/theme/app_colors.dart';
import '../providers/settings_provider.dart';

void showLanguageSheet(BuildContext context, WidgetRef ref) {
  final currentLang = ref.read(languageProvider);
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
