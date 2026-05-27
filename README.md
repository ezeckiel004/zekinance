# Ze Kinance — Guide de Développement Flutter/Dart

> Version 1.0.0 · Mai 2026 · Stack : Flutter + Firebase + Gemini API

---

## Table des Matières

1. [Prérequis & Installation](#1-prérequis--installation)
2. [Structure du Projet](#2-structure-du-projet)
3. [Configuration Firebase](#3-configuration-firebase)
4. [Dépendances (pubspec.yaml)](#4-dépendances-pubspecyaml)
5. [Architecture & State Management (Riverpod)](#5-architecture--state-management-riverpod)
6. [Modèles de Données (Firestore)](#6-modèles-de-données-firestore)
7. [Navigation (GoRouter)](#7-navigation-gorouter)
8. [Modules à Développer](#8-modules-à-développer)
9. [Intégration Gemini AI](#9-intégration-gemini-ai)
10. [Mode Hors-ligne](#10-mode-hors-ligne)
11. [Notifications (FCM)](#11-notifications-fcm)
12. [Tests](#12-tests)
13. [Build & Déploiement](#13-build--déploiement)
14. [Roadmap par Phase](#14-roadmap-par-phase)

---

## 1. Prérequis & Installation

### Environnement requis

```bash
# Flutter SDK (version minimale)
flutter --version   # >= 3.22.0

# Dart SDK (inclus dans Flutter)
dart --version      # >= 3.4.0

# Firebase CLI
npm install -g firebase-tools
firebase --version  # >= 13.x

# FlutterFire CLI
dart pub global activate flutterfire_cli
```

### Créer le projet

```bash
flutter create Ze Kinance --org com.Ze Kinance --platforms android,ios,web
cd Ze Kinance
flutterfire configure
```

### Lancer l'application

```bash
# Android
flutter run -d android

# iOS
flutter run -d ios

# Web
flutter run -d chrome

# Avec flavors (dev / prod)
flutter run --flavor dev -t lib/main_dev.dart
flutter run --flavor prod -t lib/main_prod.dart
```

---

## 2. Structure du Projet

```
Ze Kinance/
├── lib/
│   ├── main.dart                   # Point d'entrée
│   ├── main_dev.dart               # Flavor développement
│   ├── main_prod.dart              # Flavor production
│   │
│   ├── app/
│   │   ├── app.dart                # Widget racine + GoRouter
│   │   ├── theme/
│   │   │   ├── app_theme.dart      # ThemeData Material 3
│   │   │   ├── app_colors.dart     # Palette de couleurs
│   │   │   └── app_typography.dart # TextTheme
│   │   └── l10n/                   # Internationalisation
│   │       ├── app_fr.arb
│   │       ├── app_en.arb
│   │       └── app_pt.arb
│   │
│   ├── core/
│   │   ├── constants/
│   │   │   ├── app_constants.dart  # Constantes globales
│   │   │   └── firestore_paths.dart
│   │   ├── errors/
│   │   │   ├── app_exception.dart
│   │   │   └── failure.dart
│   │   ├── extensions/
│   │   │   ├── double_ext.dart     # Formatage monnaie (FCFA)
│   │   │   ├── datetime_ext.dart
│   │   │   └── string_ext.dart
│   │   └── utils/
│   │       ├── validators.dart
│   │       └── formatters.dart
│   │
│   ├── data/
│   │   ├── models/                 # Modèles Firestore
│   │   │   ├── user_model.dart
│   │   │   ├── transaction_model.dart
│   │   │   ├── budget_model.dart
│   │   │   ├── savings_goal_model.dart
│   │   │   ├── debt_model.dart
│   │   │   └── tontine_model.dart
│   │   ├── repositories/           # Accès Firestore
│   │   │   ├── auth_repository.dart
│   │   │   ├── transaction_repository.dart
│   │   │   ├── budget_repository.dart
│   │   │   ├── savings_repository.dart
│   │   │   ├── debt_repository.dart
│   │   │   └── tontine_repository.dart
│   │   └── services/
│   │       ├── firebase_service.dart
│   │       ├── gemini_service.dart  # Coach IA
│   │       ├── ocr_service.dart     # Scan reçus
│   │       └── notification_service.dart
│   │
│   ├── domain/
│   │   ├── entities/               # Entités métier pures
│   │   └── usecases/               # Logique métier
│   │
│   └── presentation/
│       ├── providers/              # Riverpod providers
│       │   ├── auth_provider.dart
│       │   ├── transaction_provider.dart
│       │   ├── budget_provider.dart
│       │   └── ...
│       ├── screens/                # Écrans
│       │   ├── auth/
│       │   │   ├── login_screen.dart
│       │   │   ├── register_screen.dart
│       │   │   └── onboarding_screen.dart
│       │   ├── dashboard/
│       │   │   └── dashboard_screen.dart
│       │   ├── budget/
│       │   │   ├── budget_screen.dart
│       │   │   └── budget_detail_screen.dart
│       │   ├── transactions/
│       │   │   ├── transactions_screen.dart
│       │   │   └── add_transaction_screen.dart
│       │   ├── savings/
│       │   │   ├── savings_screen.dart
│       │   │   └── savings_goal_screen.dart
│       │   ├── profile/
│       │   │   ├── profile_screen.dart
│       │   │   └── settings_screen.dart
│       │   └── coach/
│       │       └── coach_screen.dart
│       └── widgets/                # Widgets réutilisables
│           ├── common/
│           │   ├── app_button.dart
│           │   ├── app_card.dart
│           │   ├── app_text_field.dart
│           │   └── loading_overlay.dart
│           ├── charts/
│           │   ├── donut_chart.dart
│           │   ├── bar_chart.dart
│           │   └── progress_ring.dart
│           └── dashboard/
│               ├── balance_card.dart
│               ├── budget_progress.dart
│               └── recent_transactions.dart
│
├── test/
│   ├── unit/
│   ├── widget/
│   └── integration/
│
├── android/
├── ios/
├── web/
├── pubspec.yaml
├── analysis_options.yaml
└── firebase.json
```

---

## 3. Configuration Firebase

### Initialisation

```dart
// lib/main.dart
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart'; // généré par flutterfire configure

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(
    ProviderScope(child: Ze KinanceApp()),
  );
}
```

### Règles Firestore (firestore.rules)

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{db}/documents {
    match /users/{userId}/{document=**} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    match /tontines/{tontineId} {
      allow read: if request.auth != null &&
        request.auth.uid in resource.data.memberIds;
      allow write: if request.auth != null &&
        request.auth.uid == resource.data.adminId;
    }
  }
}
```

### Chemins Firestore (core/constants/firestore_paths.dart)

```dart
class FirestorePaths {
  static String user(String uid) => 'users/$uid';
  static String transactions(String uid) => 'users/$uid/transactions';
  static String transaction(String uid, String id) => 'users/$uid/transactions/$id';
  static String budgets(String uid) => 'users/$uid/budgets';
  static String budget(String uid, String month) => 'users/$uid/budgets/$month';
  static String savingsGoals(String uid) => 'users/$uid/savingsGoals';
  static String debts(String uid) => 'users/$uid/debts';
  static const String tontines = 'tontines';
}
```

---

## 4. Dépendances (pubspec.yaml)

```yaml
name: Ze Kinance
description: Application de gestion financière personnelle
version: 1.0.0+1

environment:
  sdk: '>=3.4.0 <4.0.0'
  flutter: '>=3.22.0'

dependencies:
  flutter:
    sdk: flutter
  flutter_localizations:
    sdk: flutter

  # Firebase
  firebase_core: ^3.3.0
  firebase_auth: ^5.1.0
  cloud_firestore: ^5.2.0
  firebase_storage: ^12.1.0
  firebase_messaging: ^15.0.0
  firebase_analytics: ^11.2.0
  firebase_crashlytics: ^4.0.0
  firebase_remote_config: ^5.0.0

  # State Management
  flutter_riverpod: ^2.5.1
  riverpod_annotation: ^2.3.5

  # Navigation
  go_router: ^14.2.0

  # HTTP & API
  dio: ^5.4.3
  retrofit: ^4.1.0

  # Formulaires & Validation
  reactive_forms: ^17.0.1
  formz: ^0.7.0

  # Graphiques
  fl_chart: ^0.68.0

  # UI & Design
  google_fonts: ^6.2.1
  flutter_animate: ^4.5.0
  lottie: ^3.1.0
  cached_network_image: ^3.3.1
  shimmer: ^3.0.0

  # Utilitaires
  intl: ^0.19.0
  equatable: ^2.0.5
  freezed_annotation: ^2.4.1
  json_annotation: ^4.9.0
  uuid: ^4.4.0
  shared_preferences: ^2.2.3
  hive_flutter: ^1.1.0           # Cache local hors-ligne
  connectivity_plus: ^6.0.3
  image_picker: ^1.1.2           # Scan reçus
  google_mlkit_text_recognition: ^0.13.0  # OCR
  permission_handler: ^11.3.1
  local_auth: ^2.3.0             # Biométrie / PIN
  flutter_local_notifications: ^17.2.2
  path_provider: ^2.1.3
  pdf: ^3.11.1                   # Export PDF
  share_plus: ^10.0.0
  url_launcher: ^6.3.0
  speech_to_text: ^6.6.2         # Saisie vocale

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^4.0.0
  build_runner: ^2.4.11
  freezed: ^2.5.2
  json_serializable: ^6.8.0
  riverpod_generator: ^2.4.0
  retrofit_generator: ^8.1.0
  mockito: ^5.4.4
  mocktail: ^1.0.3

flutter:
  uses-material-design: true
  generate: true  # Pour l10n
  assets:
    - assets/images/
    - assets/animations/  # Lottie JSON
    - assets/icons/
```

---

## 5. Architecture & State Management (Riverpod)

### Pattern : Repository + Provider

```dart
// data/repositories/transaction_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/transaction_model.dart';
import '../../core/constants/firestore_paths.dart';

class TransactionRepository {
  final FirebaseFirestore _firestore;
  TransactionRepository(this._firestore);

  Stream<List<TransactionModel>> watchTransactions(String uid, {int limit = 20}) {
    return _firestore
        .collection(FirestorePaths.transactions(uid))
        .orderBy('date', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => TransactionModel.fromFirestore(doc))
            .toList());
  }

  Future<void> addTransaction(String uid, TransactionModel tx) async {
    await _firestore
        .collection(FirestorePaths.transactions(uid))
        .doc(tx.id)
        .set(tx.toFirestore());
  }

  Future<void> deleteTransaction(String uid, String txId) async {
    await _firestore
        .doc(FirestorePaths.transaction(uid, txId))
        .delete();
  }
}
```

```dart
// presentation/providers/transaction_provider.dart
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../data/models/transaction_model.dart';
import '../../data/repositories/transaction_repository.dart';
part 'transaction_provider.g.dart';

@riverpod
TransactionRepository transactionRepository(TransactionRepositoryRef ref) {
  return TransactionRepository(FirebaseFirestore.instance);
}

@riverpod
Stream<List<TransactionModel>> transactions(TransactionsRef ref, String uid) {
  return ref.watch(transactionRepositoryProvider).watchTransactions(uid);
}

@riverpod
class AddTransaction extends _$AddTransaction {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  Future<void> add(String uid, TransactionModel tx) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() =>
        ref.read(transactionRepositoryProvider).addTransaction(uid, tx));
  }
}
```

---

## 6. Modèles de Données (Firestore)

### Transaction

```dart
// data/models/transaction_model.dart
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
part 'transaction_model.freezed.dart';
part 'transaction_model.g.dart';

enum TransactionType { income, expense }

@freezed
class TransactionModel with _$TransactionModel {
  const factory TransactionModel({
    required String id,
    required TransactionType type,
    required double amount,
    required String category,
    required String description,
    required DateTime date,
    String? receiptUrl,
    @Default(false) bool isRecurring,
    String? recurringFrequency,
  }) = _TransactionModel;

  factory TransactionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TransactionModel(
      id: doc.id,
      type: data['type'] == 'income' ? TransactionType.income : TransactionType.expense,
      amount: (data['amount'] as num).toDouble(),
      category: data['category'] as String,
      description: data['description'] as String,
      date: (data['date'] as Timestamp).toDate(),
      receiptUrl: data['receiptUrl'] as String?,
      isRecurring: data['isRecurring'] as bool? ?? false,
    );
  }

  factory TransactionModel.fromJson(Map<String, dynamic> json) =>
      _$TransactionModelFromJson(json);
}

extension TransactionModelX on TransactionModel {
  Map<String, dynamic> toFirestore() => {
    'type': type.name,
    'amount': amount,
    'category': category,
    'description': description,
    'date': Timestamp.fromDate(date),
    'receiptUrl': receiptUrl,
    'isRecurring': isRecurring,
  };
}
```

### Budget

```dart
// data/models/budget_model.dart
@freezed
class BudgetModel with _$BudgetModel {
  const factory BudgetModel({
    required String month,           // Format: 'YYYY-MM'
    required Map<String, CategoryBudget> categories,
    required double totalBudget,
    required double totalEpargneObjectif,
  }) = _BudgetModel;
}

@freezed
class CategoryBudget with _$CategoryBudget {
  const factory CategoryBudget({
    required double limite,
    @Default(0.0) double depense,
  }) = _CategoryBudget;

  const CategoryBudget._();
  double get pourcentage => limite > 0 ? (depense / limite * 100).clamp(0, 100) : 0;
  double get restant => (limite - depense).clamp(0, double.infinity);
  bool get enAlerte => pourcentage >= 70;
  bool get critique => pourcentage >= 90;
}
```

### Objectif d'épargne

```dart
@freezed
class SavingsGoalModel with _$SavingsGoalModel {
  const factory SavingsGoalModel({
    required String id,
    required String name,
    required double targetAmount,
    @Default(0.0) double currentAmount,
    required DateTime deadline,
    required String category,
    String? photoUrl,
  }) = _SavingsGoalModel;

  const SavingsGoalModel._();
  double get progression => targetAmount > 0
      ? (currentAmount / targetAmount * 100).clamp(0, 100)
      : 0;
  double get mensualiteNecessaire {
    final moisRestants = deadline.difference(DateTime.now()).inDays / 30;
    if (moisRestants <= 0) return 0;
    return (targetAmount - currentAmount) / moisRestants;
  }
}
```

---

## 7. Navigation (GoRouter)

```dart
// app/app.dart
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) {
      final isAuthenticated = authState.valueOrNull != null;
      final isAuthRoute = state.matchedLocation.startsWith('/auth');

      if (!isAuthenticated && !isAuthRoute) return '/auth/login';
      if (isAuthenticated && isAuthRoute) return '/dashboard';
      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
      GoRoute(
        path: '/auth',
        builder: (_, __) => const AuthShell(),
        routes: [
          GoRoute(path: 'login', builder: (_, __) => const LoginScreen()),
          GoRoute(path: 'register', builder: (_, __) => const RegisterScreen()),
          GoRoute(path: 'onboarding', builder: (_, __) => const OnboardingScreen()),
        ],
      ),
      StatefulShellRoute.indexedStack(
        builder: (_, __, shell) => MainShell(shell: shell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(path: '/dashboard', builder: (_, __) => const DashboardScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/budget', builder: (_, __) => const BudgetScreen()),
            GoRoute(path: '/budget/:id', builder: (context, state) =>
                BudgetDetailScreen(categoryId: state.pathParameters['id']!)),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/transactions', builder: (_, __) => const TransactionsScreen()),
            GoRoute(path: '/transactions/add', builder: (_, __) => const AddTransactionScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/savings', builder: (_, __) => const SavingsScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),
            GoRoute(path: '/coach', builder: (_, __) => const CoachScreen()),
          ]),
        ],
      ),
    ],
  );
});
```

---

## 8. Modules à Développer

### 8.1 Authentification

```dart
// data/repositories/auth_repository.dart
class AuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<UserCredential> signInWithEmail(String email, String password) =>
      _auth.signInWithEmailAndPassword(email: email, password: password);

  Future<UserCredential> signInWithGoogle() async {
    final googleUser = await GoogleSignIn().signIn();
    final googleAuth = await googleUser!.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    return _auth.signInWithCredential(credential);
  }

  Future<UserCredential> signInWithPhone(String verificationId, String smsCode) {
    final credential = PhoneAuthProvider.credential(
      verificationId: verificationId, smsCode: smsCode,
    );
    return _auth.signInWithCredential(credential);
  }

  Future<void> signOut() => _auth.signOut();
}
```

### 8.2 Dashboard — Score de Santé Financière

```dart
// core/utils/financial_health_calculator.dart
class FinancialHealthCalculator {
  /// Score sur 100 basé sur la situation financière
  static int calculate({
    required double revenuMensuel,
    required double depensesTotales,
    required double epargneMensuelle,
    required double dettesTotal,
    required int objectifsAtteints,
    required int objectifsTotal,
  }) {
    int score = 0;

    // Taux d'épargne (max 30 pts)
    final tauxEpargne = revenuMensuel > 0 ? epargneMensuelle / revenuMensuel : 0;
    score += (tauxEpargne * 150).clamp(0, 30).toInt();

    // Taux de dépenses (max 30 pts)
    final tauxDepenses = revenuMensuel > 0 ? depensesTotales / revenuMensuel : 1;
    if (tauxDepenses <= 0.50) score += 30;
    else if (tauxDepenses <= 0.70) score += 20;
    else if (tauxDepenses <= 0.90) score += 10;

    // Gestion des dettes (max 20 pts)
    final ratioEndettement = revenuMensuel > 0 ? dettesTotal / (revenuMensuel * 12) : 1;
    if (ratioEndettement == 0) score += 20;
    else if (ratioEndettement < 0.3) score += 15;
    else if (ratioEndettement < 0.6) score += 8;

    // Atteinte des objectifs (max 20 pts)
    if (objectifsTotal > 0) {
      score += ((objectifsAtteints / objectifsTotal) * 20).toInt();
    }

    return score.clamp(0, 100);
  }

  static String getLabel(int score) {
    if (score >= 80) return 'Excellent';
    if (score >= 60) return 'Bien';
    if (score >= 40) return 'Moyen';
    return 'Critique';
  }

  static Color getColor(int score) {
    if (score >= 80) return const Color(0xFF22C55E);
    if (score >= 60) return const Color(0xFF84CC16);
    if (score >= 40) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }
}
```

### 8.3 Ajout Transaction — Saisie Vocale

```dart
// presentation/screens/transactions/add_transaction_screen.dart (extrait)
class _VoiceInputButton extends ConsumerStatefulWidget { ... }

class _VoiceInputButtonState extends ConsumerState<_VoiceInputButton> {
  final SpeechToText _speech = SpeechToText();

  Future<void> _startListening() async {
    await _speech.listen(
      onResult: (result) {
        if (result.finalResult) {
          _parseVoiceInput(result.recognizedWords);
        }
      },
      localeId: 'fr_FR',
    );
  }

  void _parseVoiceInput(String text) {
    // Exemple: "J'ai dépensé 5000 francs pour le marché"
    final amountRegex = RegExp(r'(\d+(?:\s?\d+)*)\s*(?:francs?|FCFA|CFA)');
    final match = amountRegex.firstMatch(text);
    if (match != null) {
      final amount = double.tryParse(match.group(1)!.replaceAll(' ', ''));
      // Mettre à jour le formulaire avec le montant détecté
      ref.read(addTransactionFormProvider.notifier).setAmount(amount);
    }
  }
}
```

### 8.4 Scan Reçu (OCR)

```dart
// data/services/ocr_service.dart
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class OcrService {
  final textRecognizer = TextRecognizer();

  Future<OcrResult> extractFromImage(String imagePath) async {
    final inputImage = InputImage.fromFilePath(imagePath);
    final recognized = await textRecognizer.processImage(inputImage);

    double? amount;
    String? merchant;
    DateTime? date;

    for (final block in recognized.blocks) {
      // Détecter un montant (ex: "5 000 FCFA", "2500F")
      final amountMatch = RegExp(r'(\d[\d\s]*)\s*(?:FCFA|F\b|CFA)')
          .firstMatch(block.text);
      if (amountMatch != null) {
        amount = double.tryParse(amountMatch.group(1)!.replaceAll(' ', ''));
      }
      // Détecter une date
      final dateMatch = RegExp(r'\d{2}/\d{2}/\d{4}').firstMatch(block.text);
      if (dateMatch != null) {
        date = DateFormat('dd/MM/yyyy').parse(dateMatch.group(0)!);
      }
    }
    return OcrResult(amount: amount, merchant: merchant, date: date,
        rawText: recognized.text);
  }
}

class OcrResult {
  final double? amount;
  final String? merchant;
  final DateTime? date;
  final String rawText;
  const OcrResult({this.amount, this.merchant, this.date, required this.rawText});
}
```

### 8.5 Méthode 50/30/20

```dart
// core/utils/budget_calculator.dart
class BudgetCalculator {
  /// Applique la méthode 50/30/20 au revenu mensuel
  static Map<String, double> apply5030Rule(double revenuMensuel) => {
    'besoins': revenuMensuel * 0.50,   // Loyer, alimentation, santé
    'envies': revenuMensuel * 0.30,    // Loisirs, vêtements, restaurants
    'epargne': revenuMensuel * 0.20,   // Épargne & investissement
  };

  /// Méthode avalanche : rembourser la dette au taux le plus élevé en premier
  static List<DebtModel> sortByAvalanche(List<DebtModel> debts) =>
      [...debts]..sort((a, b) => b.interestRate.compareTo(a.interestRate));

  /// Méthode boule de neige : rembourser la plus petite dette en premier
  static List<DebtModel> sortBySnowball(List<DebtModel> debts) =>
      [...debts]..sort((a, b) => a.remaining.compareTo(b.remaining));

  /// Simulateur d'épargne
  static double simulateGrowth({
    required double montantInitial,
    required double mensualite,
    required int mois,
    double tauxAnnuel = 0.05,
  }) {
    final tauxMensuel = tauxAnnuel / 12;
    double total = montantInitial;
    for (int i = 0; i < mois; i++) {
      total = total * (1 + tauxMensuel) + mensualite;
    }
    return total;
  }
}
```

---

## 9. Intégration Gemini AI

```dart
// data/services/gemini_service.dart
import 'package:dio/dio.dart';

class GeminiService {
  static const _baseUrl = 'https://generativelanguage.googleapis.com/v1beta';
  static const _model = 'gemini-1.5-flash';  // Free tier

  final Dio _dio;
  final String _apiKey;

  GeminiService({required String apiKey})
      : _apiKey = apiKey,
        _dio = Dio(BaseOptions(baseUrl: _baseUrl));

  /// Génère un conseil financier personnalisé
  Future<String> getFinancialAdvice({
    required double revenu,
    required double depenses,
    required double epargne,
    required Map<String, double> depensesParCategorie,
    required String question,
  }) async {
    final context = '''
Tu es FinCoach, l'assistant financier personnel de Ze Kinance.
Tu parles en français, de façon simple et bienveillante.
Données de l'utilisateur :
- Revenu mensuel : ${revenu.toStringAsFixed(0)} FCFA
- Dépenses totales : ${depenses.toStringAsFixed(0)} FCFA
- Épargne ce mois : ${epargne.toStringAsFixed(0)} FCFA
- Répartition des dépenses : ${depensesParCategorie.entries.map((e) => '${e.key}: ${e.value.toStringAsFixed(0)} FCFA').join(', ')}
Réponds de façon concise (max 3 phrases), pratique et encourageante.
''';

    final response = await _dio.post(
      '/models/$_model:generateContent?key=$_apiKey',
      data: {
        'contents': [
          {'parts': [{'text': '$context\nQuestion: $question'}]}
        ],
        'generationConfig': {'maxOutputTokens': 256, 'temperature': 0.7},
      },
    );

    return response.data['candidates'][0]['content']['parts'][0]['text'] as String;
  }

  /// Analyse les dépenses et détecte les fuites financières
  Future<List<String>> analyzeSpending(Map<String, double> categories, double revenu) async {
    final prompt = '''
Analyse ces dépenses mensuelles en FCFA et identifie 3 conseils prioritaires :
${categories.entries.map((e) => '- ${e.key}: ${e.value.toStringAsFixed(0)} FCFA').join('\n')}
Revenu mensuel : ${revenu.toStringAsFixed(0)} FCFA
Retourne exactement 3 conseils courts, un par ligne, sans numérotation.
''';

    final response = await _dio.post(
      '/models/$_model:generateContent?key=$_apiKey',
      data: {
        'contents': [{'parts': [{'text': prompt}]}],
        'generationConfig': {'maxOutputTokens': 200},
      },
    );

    final text = response.data['candidates'][0]['content']['parts'][0]['text'] as String;
    return text.trim().split('\n').where((l) => l.isNotEmpty).take(3).toList();
  }
}
```

---

## 10. Mode Hors-ligne

```dart
// data/services/offline_sync_service.dart
// Utilise Hive pour le cache local + Firestore offline persistence

class OfflineSyncService {
  static Future<void> init() async {
    // Activer la persistance Firestore (activée par défaut sur mobile)
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );

    // Init Hive pour données critiques
    await Hive.initFlutter();
    await Hive.openBox<String>('transactions_cache');
    await Hive.openBox<String>('budget_cache');
    await Hive.openBox<String>('user_prefs');
  }
}
```

```dart
// Vérification de connectivité dans un provider
@riverpod
Stream<ConnectivityResult> connectivity(ConnectivityRef ref) =>
    Connectivity().onConnectivityChanged.map((results) => results.first);

@riverpod
bool isOnline(IsOnlineRef ref) {
  final connectivity = ref.watch(connectivityProvider).valueOrNull;
  return connectivity != null && connectivity != ConnectivityResult.none;
}
```

---

## 11. Notifications (FCM)

```dart
// data/services/notification_service.dart
class NotificationService {
  static final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    await _local.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      ),
    );

    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    FirebaseMessaging.onBackgroundMessage(_handleBackgroundMessage);
  }

  static Future<void> scheduleMonthlyReminder() async {
    // Rappel épargne le 1er de chaque mois
    await _local.zonedSchedule(
      1,
      '💰 Rappel épargne Ze Kinance',
      'N\'oubliez pas de mettre de côté votre épargne ce mois !',
      _nextFirstOfMonth(),
      const NotificationDetails(
        android: AndroidNotificationDetails('reminders', 'Rappels Ze Kinance',
            importance: Importance.high),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.dayOfMonthAndTime,
    );
  }

  static Future<void> sendBudgetAlert({
    required String category,
    required double pourcentage,
  }) async {
    final emoji = pourcentage >= 100 ? '🚨' : '⚠️';
    await _local.show(
      category.hashCode,
      '$emoji Budget $category',
      '${pourcentage.toInt()}% de votre budget $category utilisé',
      const NotificationDetails(
        android: AndroidNotificationDetails('budget_alerts', 'Alertes Budget',
            importance: Importance.high),
      ),
    );
  }

  static TZDateTime _nextFirstOfMonth() {
    final now = TZDateTime.now(local);
    return TZDateTime(local, now.year, now.month + 1, 1, 9, 0);
  }
}
```

---

## 12. Tests

### Tests Unitaires

```dart
// test/unit/financial_health_calculator_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:Ze Kinance/core/utils/financial_health_calculator.dart';

void main() {
  group('FinancialHealthCalculator', () {
    test('score excellent quand épargne > 20% et pas de dettes', () {
      final score = FinancialHealthCalculator.calculate(
        revenuMensuel: 300000,
        depensesTotales: 180000,
        epargneMensuelle: 70000,
        dettesTotal: 0,
        objectifsAtteints: 2,
        objectifsTotal: 3,
      );
      expect(score, greaterThanOrEqualTo(75));
    });

    test('score critique quand dépenses > revenu', () {
      final score = FinancialHealthCalculator.calculate(
        revenuMensuel: 200000,
        depensesTotales: 210000,
        epargneMensuelle: 0,
        dettesTotal: 500000,
        objectifsAtteints: 0,
        objectifsTotal: 2,
      );
      expect(score, lessThan(40));
    });
  });
}
```

### Tests Widget

```dart
// test/widget/dashboard_screen_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  testWidgets('DashboardScreen affiche le solde disponible', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authStateProvider.overrideWithValue(AsyncData(mockUser)),
          transactionsProvider.overrideWith((_) => Stream.value(mockTransactions)),
        ],
        child: const MaterialApp(home: DashboardScreen()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Solde disponible'), findsOneWidget);
  });
}
```

### Lancer les tests

```bash
# Tous les tests
flutter test

# Avec couverture (objectif > 70%)
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html

# Tests d'intégration
flutter test integration_test/
```

---

## 13. Build & Déploiement

### Android

```bash
# Debug APK
flutter build apk --debug

# Release APK (signature requise)
flutter build apk --release

# App Bundle (recommandé pour Play Store)
flutter build appbundle --release

# Avec flavor prod
flutter build appbundle --flavor prod -t lib/main_prod.dart
```

### iOS

```bash
flutter build ios --release
# Puis ouvrir Xcode pour archiver et uploader sur TestFlight
```

### Web (Firebase Hosting)

```bash
flutter build web --release --web-renderer canvaskit

# Déployer
firebase deploy --only hosting
```

### Variables d'environnement

```dart
// lib/core/constants/app_env.dart
// Utiliser --dart-define pour injecter les clés API
class AppEnv {
  static const geminiApiKey = String.fromEnvironment('GEMINI_API_KEY');
  static const flavor = String.fromEnvironment('FLAVOR', defaultValue: 'dev');
}
```

```bash
# Lancer avec clé API
flutter run --dart-define=GEMINI_API_KEY=votre_cle --dart-define=FLAVOR=prod
```

---

## 14. Roadmap par Phase

| Phase | Durée | Priorité | Modules Flutter |
|-------|-------|----------|-----------------|
| **Phase 0** — Setup | 2 sem | 🔴 Critique | Projet Flutter, Firebase, GoRouter, Riverpod, thème Material 3 |
| **Phase 1** — Core MVP | 6 sem | 🔴 Critique | Auth (email/Google/tel), Transactions CRUD, Budget basique, Dashboard |
| **Phase 2** — Épargne | 4 sem | 🟠 Haute | Objectifs épargne, épargne automatique, défis 52 semaines |
| **Phase 3** — IA & Coach | 4 sem | 🟠 Haute | Gemini AI, Coach IA, Académie financière, saisie vocale, OCR |
| **Phase 4** — Avancé | 4 sem | 🟡 Moyenne | Investissement, Dettes, Tontines, Export PDF, Rapport mensuel |
| **Phase 5** — Social | 3 sem | 🟢 Basse | Défis entre amis, classement, partage |

### Checklist Phase 0

- [ ] `flutter create Ze Kinance` avec toutes les plateformes
- [ ] `flutterfire configure` — connecter Firebase
- [ ] Configurer les flavors `dev` et `prod`
- [ ] Ajouter toutes les dépendances dans `pubspec.yaml`
- [ ] Implémenter `AppTheme` Material 3 avec couleurs Ze Kinance
- [ ] Configurer GoRouter avec les routes de base
- [ ] Mettre en place Riverpod `ProviderScope`
- [ ] Configurer `analysis_options.yaml` (linting strict)
- [ ] Configurer CI/CD (GitHub Actions ou Codemagic)
- [ ] Déployer les règles Firestore

---

*Document généré depuis le Cahier des Charges Ze Kinance v1.0.0 — Mai 2026*
*Stack : Flutter 3.22+ / Dart 3.4+ / Firebase Spark / Gemini 1.5 Flash*