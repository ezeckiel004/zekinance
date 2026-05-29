# Plan d'implémentation — Phase 0 : Configuration et Architecture de Base (Ze Kinance)

Ce plan détaille la mise en place de la structure de base du projet **Ze Kinance**, conformément au guide de développement fourni dans le fichier [README.md](file:///C:/Users/Mac/Documents/Me/zekinance/README.md).

---

## Synthèse du Plan de Base

### 1. Configuration des Dépendances & Linter
- **pubspec.yaml** : Ajout et configuration des dépendances principales (Riverpod, GoRouter, Google Fonts, Flutter Animate, Intl).
- **analysis_options.yaml** : Activation de règles de linting strictes pour assurer la propreté et la robustesse du code.

### 2. Design System & Thème Premium (Material 3 Sombre)
- **app_colors.dart** : Palette moderne de style Fintech émeraude (`#00C853`) et néon (`#00E5FF`) sur fond bleu nuit profond (`#090D16`).
- **app_typography.dart** : Outfit pour les titres géométriques futuristes, Inter pour un texte d'une lisibilité maximale.
- **app_theme.dart** : Intégration complète des boutons lisses, des inputs arrondis et de la barre de navigation.

### 3. Architecture & Navigation Réactive
- **app.dart** : Configuration multiniveau sous `GoRouter` avec redirections automatiques basées sur l'état d'authentification.
- **main_shell.dart** : Barre de navigation par onglets (Dashboard, Budgets, Flux, Épargne, Coach).
- **auth_provider.dart** : Gestionnaire d'état de l'authentification avec un utilisateur factice ("MockUser") actif par défaut pour faciliter le test.

### 4. Modules Fonctionnels Riches (Mockés)
- **dashboard_screen.dart** : Solde global disponible, raccourcis rapides, score de santé et flux récents.
- **budget_screen.dart** / **budget_detail_screen.dart** : Suivi budgétaire 50/30/20 avec alertes de dépassement (orange/rouge).
- **add_transaction_screen.dart** : Formulaire avec actions intelligentes d'**OCR Reçu** et de **Saisie Vocale** interactives.
- **savings_screen.dart** : Objectifs d'épargne avec calcul dynamique des mensualités requises.
- **coach_screen.dart** : FinCoach IA simulant des conseils pertinents en français.
- **profile_screen.dart** : Paramètres utilisateur et explications du Mock/Local.

---

## Plan de Vérification

### Tests Automatisés
- Exécution de `flutter analyze` pour valider la qualité du typage et de la syntaxe.
- Exécution de `flutter test` pour lancer la suite de tests unitaires.
