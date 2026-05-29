class AppConstants {
  static const String appName = 'Ze Kinance';
  static const String currencySymbol = 'FCFA';
  static const String currencyName = 'Franc CFA';
  
  // Storage Keys
  static const String keyFirstTimeUser = 'first_time_user';
  static const String keyThemeMode = 'theme_mode';
  static const String keyAuthToken = 'auth_token';

  // Format templates
  static const String dateFormatShort = 'dd/MM/yyyy';
  static const String dateFormatMonth = 'MMMM yyyy';
  
  // Financial rules
  static const double savingsTargetRate = 0.20; // 20% in the 50/30/20 rule
  static const double needsTargetRate = 0.50;    // 50% in the 50/30/20 rule
  static const double wantsTargetRate = 0.30;    // 30% in the 50/30/20 rule
}
