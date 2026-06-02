import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../presentation/providers/settings_provider.dart';

class Translations {
  static const Map<String, Map<String, String>> _keys = {
    'fr': {
      // General
      'cancel': 'Annuler',
      'save': 'Enregistrer',
      'edit': 'Modifier',
      'delete': 'Supprimer',
      'loading': 'Chargement...',
      'error': 'Une erreur est survenue',
      'confirm': 'Confirmer',

      // Navigation / Shell
      'nav_home': 'Accueil',
      'nav_budgets': 'Budgets',
      'nav_transactions': 'Flux',
      'nav_savings': 'Épargne',
      'nav_coach': 'Coach IA',
      'nav_profile': 'Mon Profil',

      // Splash Screen
      'splash_subtitle': 'La gestion financière simplifiée et intelligente',

      // Auth (Login / Register / Onboarding)
      'login_title': 'Bon retour !',
      'login_subtitle': 'Connectez-vous pour gérer vos finances',
      'email_label': 'Adresse Email',
      'password_label': 'Mot de passe',
      'login_btn': 'Se connecter',
      'no_account': 'Pas encore de compte ? Inscription',
      'register_title': 'Inscription',
      'register_subtitle': 'Créez un compte pour commencer',
      'name_label': 'Nom complet',
      'register_btn': 'S\'inscrire',
      'already_account': 'Déjà un compte ? Connexion',
      
      'onboarding_title': 'Bienvenue ! 🌟',
      'onboarding_subtitle': 'Configurons votre profil pour une gestion financière intelligente.',
      'onboarding_income_label': 'Quel est votre revenu mensuel ?',
      'onboarding_income_hint': 'Ex: 250000 FCFA',
      'onboarding_btn': 'Commencer l\'aventure',

      // Dashboard / Home Screen
      'home_greeting': 'Bonjour,',
      'home_available': 'Solde disponible',
      'home_saved': 'Total épargné',
      'home_health': 'Santé financière',
      'home_health_excellent': 'Excellent',
      'home_health_medium': 'Moyen',
      'home_health_critical': 'Critique',
      'home_recent_tx': 'Transactions récentes',
      'home_see_all': 'Tout voir',
      'home_quick_actions': 'Actions rapides',
      'home_action_add_tx': 'Transaction',
      'home_action_budget': 'Objectif',
      'home_coach_bubble': 'Besoin d\'un conseil financier ? Parlez à notre IA !',

      // Budget Screen
      'budget_title': 'Budgets',
      'budget_total_expense': 'Dépense totale',
      'budget_remaining': 'restant sur',
      'budget_categories': 'Catégories de budget',
      'budget_add_category': 'Ajouter une catégorie',
      'budget_edit': 'Modifier le budget',
      'budget_create': 'Créer un budget',
      'budget_category_label': 'Nom de la catégorie',
      'budget_allocated_label': 'Montant alloué',
      'budget_allocated_hint': 'Ex: 50000',
      'budget_add_success': 'Catégorie ajoutée avec succès',
      'budget_edit_title': 'Modifier le budget mensuel',
      'budget_edit_subtitle': 'Définissez votre enveloppe budgétaire globale',
      'budget_income_limit': 'Le budget total ne peut pas dépasser votre revenu mensuel de ',

      // Budget Detail Screen
      'budget_detail_title': 'Détails du budget',
      'budget_detail_expenses': 'Dépenses',
      'budget_detail_allocated': 'Alloué',
      'budget_detail_remaining': 'Restant',
      'budget_detail_tx_history': 'Transactions de la catégorie',
      'budget_detail_no_tx': 'Aucune transaction pour le moment',

      // Transactions Screen
      'tx_title': 'Transactions',
      'tx_filter_all': 'Toutes les catégories',
      'tx_search_hint': 'Rechercher une transaction...',
      'tx_no_results': 'Aucune transaction trouvée',

      // Add Transaction Screen
      'add_tx_title': 'Nouvelle Transaction',
      'add_tx_amount': 'Montant',
      'add_tx_type': 'Type de transaction',
      'add_tx_type_expense': 'Dépense',
      'add_tx_type_income': 'Revenu',
      'add_tx_category': 'Catégorie',
      'add_tx_date': 'Date de la transaction',
      'add_tx_description': 'Description',
      'add_tx_description_hint': 'Ex: Courses supermarché',
      'add_tx_btn': 'Ajouter la transaction',
      'add_tx_success': 'Transaction ajoutée avec succès',
      'add_tx_error_amount': 'Veuillez entrer un montant valide',
      'add_tx_error_desc': 'Veuillez entrer une description',

      // Savings Screen
      'savings_title': 'Objectifs d\'Épargne',
      'savings_total': 'Épargne totale',
      'savings_create_goal': 'Créer un objectif',
      'savings_no_goals': 'Aucun objectif d\'épargne. Commencez à épargner dès aujourd\'hui !',
      'savings_target': 'Cible',
      'savings_reached': 'Atteint',
      'savings_add': 'Épargner',
      'savings_withdraw': 'Retirer',
      'savings_new_goal_title': 'Nouvel objectif d\'épargne',
      'savings_goal_name': 'Nom de l\'objectif',
      'savings_goal_name_hint': 'Ex: Voyage au Kenya',
      'savings_goal_target': 'Montant cible',
      'savings_goal_target_hint': 'Ex: 1000000',
      'savings_goal_current': 'Montant initial',
      'savings_goal_current_hint': 'Ex: 50000',
      'savings_goal_category': 'Catégorie',
      'savings_add_fund_title': 'Ajouter des fonds',
      'savings_withdraw_fund_title': 'Retirer des fonds',
      'savings_amount_label': 'Montant',
      'savings_goal_added': 'Objectif d\'épargne créé avec succès',
      'savings_fund_updated': 'Fonds mis à jour avec succès',

      // Coach Screen
      'coach_title': 'Coach IA',
      'coach_subtitle': 'Votre assistant financier personnel',
      'coach_placeholder': 'Posez une question sur votre budget, épargne...',
      'coach_suggest_1': 'Comment économiser 10% de plus ce mois-ci ?',
      'coach_suggest_2': 'Analyse mon budget actuel',
      'coach_suggest_3': 'Est-ce que je peux acheter une voiture avec mes économies ?',
      'coach_send_hint': 'Écrivez votre message...',

      // Profile Screen
      'profile_title': 'Mon Profil',
      'account_details': 'Détails du compte',
      'account_details_sub': 'Modifier vos informations personnelles',
      'security_biometrics': 'Sécurité & Biométrie',
      'security_sub_on': 'Sécurité biométrique activée',
      'security_sub_off': 'Activer le verrouillage par empreinte / visage',
      'notifications': 'Paramètres des notifications',
      'notifications_sub': 'Gérer les alertes budgétaires (Désactivé)',
      'theme_title': 'Mode sombre actif',
      'theme_dark_sub': 'Le mode sombre premium est activé',
      'theme_light_sub': 'Le mode clair est activé',
      'logout': 'Se déconnecter',
      'language': 'Langue / Language',
      'language_sub': 'Français (Sélectionné)',
      'edit_profile': 'Modifier le profil',
      'full_name': 'Nom complet',
      'auth_required': 'Authentification requise',
      'auth_reason': 'Veuillez vous authentifier pour modifier ce paramètre',
      'auth_failed': 'Échec de l\'authentification',
      'auth_not_available': 'Biométrie non disponible sur ce téléphone',
    },
    'en': {
      // General
      'cancel': 'Cancel',
      'save': 'Save',
      'edit': 'Edit',
      'delete': 'Delete',
      'loading': 'Loading...',
      'error': 'An error occurred',
      'confirm': 'Confirm',

      // Navigation / Shell
      'nav_home': 'Home',
      'nav_budgets': 'Budgets',
      'nav_transactions': 'Flow',
      'nav_savings': 'Savings',
      'nav_coach': 'IA Coach',
      'nav_profile': 'My Profile',

      // Splash Screen
      'splash_subtitle': 'Smart and simplified financial management',

      // Auth (Login / Register / Onboarding)
      'login_title': 'Welcome back!',
      'login_subtitle': 'Log in to manage your finances',
      'email_label': 'Email Address',
      'password_label': 'Password',
      'login_btn': 'Log In',
      'no_account': 'Don\'t have an account? Sign Up',
      'register_title': 'Register',
      'register_subtitle': 'Create an account to get started',
      'name_label': 'Full Name',
      'register_btn': 'Register',
      'already_account': 'Already have an account? Log In',
      
      'onboarding_title': 'Welcome! 🌟',
      'onboarding_subtitle': 'Let\'s configure your profile for smart financial management.',
      'onboarding_income_label': 'What is your monthly income?',
      'onboarding_income_hint': 'e.g. 250000 FCFA',
      'onboarding_btn': 'Start the adventure',

      // Dashboard / Home Screen
      'home_greeting': 'Hello,',
      'home_available': 'Available balance',
      'home_saved': 'Total saved',
      'home_health': 'Financial health',
      'home_health_excellent': 'Excellent',
      'home_health_medium': 'Medium',
      'home_health_critical': 'Critical',
      'home_recent_tx': 'Recent transactions',
      'home_see_all': 'See all',
      'home_quick_actions': 'Quick Actions',
      'home_action_add_tx': 'Transaction',
      'home_action_budget': 'Savings Goal',
      'home_coach_bubble': 'Need financial advice? Ask our AI!',

      // Budget Screen
      'budget_title': 'Budgets',
      'budget_total_expense': 'Total Expense',
      'budget_remaining': 'remaining of',
      'budget_categories': 'Budget Categories',
      'budget_add_category': 'Add Category',
      'budget_edit': 'Edit Budget',
      'budget_create': 'Create Budget',
      'budget_category_label': 'Category Name',
      'budget_allocated_label': 'Allocated Amount',
      'budget_allocated_hint': 'e.g. 50000',
      'budget_add_success': 'Category added successfully',
      'budget_edit_title': 'Modify Monthly Budget',
      'budget_edit_subtitle': 'Define your global monthly spending envelope',
      'budget_income_limit': 'Total budget cannot exceed your monthly income of ',

      // Budget Detail Screen
      'budget_detail_title': 'Budget Details',
      'budget_detail_expenses': 'Expenses',
      'budget_detail_allocated': 'Allocated',
      'budget_detail_remaining': 'Remaining',
      'budget_detail_tx_history': 'Transactions in Category',
      'budget_detail_no_tx': 'No transactions for now',

      // Transactions Screen
      'tx_title': 'Transactions',
      'tx_filter_all': 'All Categories',
      'tx_search_hint': 'Search a transaction...',
      'tx_no_results': 'No transactions found',

      // Add Transaction Screen
      'add_tx_title': 'New Transaction',
      'add_tx_amount': 'Amount',
      'add_tx_type': 'Transaction Type',
      'add_tx_type_expense': 'Expense',
      'add_tx_type_income': 'Income',
      'add_tx_category': 'Category',
      'add_tx_date': 'Transaction Date',
      'add_tx_description': 'Description',
      'add_tx_description_hint': 'e.g. Supermarket grocery',
      'add_tx_btn': 'Add Transaction',
      'add_tx_success': 'Transaction added successfully',
      'add_tx_error_amount': 'Please enter a valid amount',
      'add_tx_error_desc': 'Please enter a description',

      // Savings Screen
      'savings_title': 'Savings Goals',
      'savings_total': 'Total Savings',
      'savings_create_goal': 'Create Goal',
      'savings_no_goals': 'No savings goals yet. Start saving today!',
      'savings_target': 'Target',
      'savings_reached': 'Reached',
      'savings_add': 'Save',
      'savings_withdraw': 'Withdraw',
      'savings_new_goal_title': 'New Savings Goal',
      'savings_goal_name': 'Goal Name',
      'savings_goal_name_hint': 'e.g. Trip to Kenya',
      'savings_goal_target': 'Target Amount',
      'savings_goal_target_hint': 'e.g. 1000000',
      'savings_goal_current': 'Initial Amount',
      'savings_goal_current_hint': 'e.g. 50000',
      'savings_goal_category': 'Category',
      'savings_add_fund_title': 'Add Funds',
      'savings_withdraw_fund_title': 'Withdraw Funds',
      'savings_amount_label': 'Amount',
      'savings_goal_added': 'Savings goal created successfully',
      'savings_fund_updated': 'Funds updated successfully',

      // Coach Screen
      'coach_title': 'IA Coach',
      'coach_subtitle': 'Your personal financial assistant',
      'coach_placeholder': 'Ask a question about your budget, savings...',
      'coach_suggest_1': 'How can I save 10% more this month?',
      'coach_suggest_2': 'Analyze my current budget',
      'coach_suggest_3': 'Can I afford to buy a car with my savings?',
      'coach_send_hint': 'Type your message...',

      // Profile Screen
      'profile_title': 'My Profile',
      'account_details': 'Account Details',
      'account_details_sub': 'Modify your personal information',
      'security_biometrics': 'Security & Biometrics',
      'security_sub_on': 'Biometric security enabled',
      'security_sub_off': 'Enable fingerprint / face unlock',
      'notifications': 'Notification Settings',
      'notifications_sub': 'Manage budget alerts (Disabled)',
      'theme_title': 'Dark Mode Active',
      'theme_dark_sub': 'Premium dark mode is enabled',
      'theme_light_sub': 'Light mode is enabled',
      'logout': 'Log Out',
      'language': 'Language / Langue',
      'language_sub': 'English (Selected)',
      'edit_profile': 'Edit Profile',
      'full_name': 'Full Name',
      'auth_required': 'Authentication Required',
      'auth_reason': 'Please authenticate to change this setting',
      'auth_failed': 'Authentication failed',
      'auth_not_available': 'Biometrics not available on this phone',
    }
  };

  static String getText(String lang, String key) {
    return _keys[lang]?[key] ?? _keys['fr']?[key] ?? key;
  }
}

extension LocalizationExt on BuildContext {
  String tr(WidgetRef ref, String key) {
    final lang = ref.watch(languageProvider);
    return Translations.getText(lang, key);
  }
}
