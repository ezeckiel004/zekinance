import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/models/user_model.dart';

// Provider for AuthRepository
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

// StreamProvider that listens to Firebase AuthState changes
final firebaseUserStreamProvider = StreamProvider<User?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
});

// StateNotifier to manage user profile and sign in/out operations
final authStateProvider = StateNotifierProvider<AuthNotifier, UserModel?>((ref) {
  final authRepo = ref.watch(authRepositoryProvider);
  final firebaseUserAsync = ref.watch(firebaseUserStreamProvider);

  final notifier = AuthNotifier(authRepo);

  // Listen to the stream and update notifier state accordingly
  firebaseUserAsync.whenData((user) async {
    if (user == null) {
      notifier.setOffline();
    } else {
      await notifier.loadUserData(user.uid, user.email ?? '', user.displayName ?? '');
    }
  });

  return notifier;
});

class AuthNotifier extends StateNotifier<UserModel?> {
  final AuthRepository _authRepo;

  AuthNotifier(this._authRepo) : super(null);

  void setOffline() {
    state = null;
  }

  Future<void> loadUserData(String uid, String email, String displayName) async {
    final userData = await _authRepo.getUserData(uid);
    if (userData != null) {
      state = userData;
    } else {
      state = UserModel(
        uid: uid,
        email: email,
        displayName: displayName,
        monthlyIncome: 0.0,
      );
    }
  }

  Future<void> login(String email, String password) async {
    await _authRepo.signInWithEmail(email, password);
  }

  Future<void> register(String email, String password, String displayName) async {
    await _authRepo.signUpWithEmail(
      email: email,
      password: password,
      displayName: displayName,
    );
  }

  Future<void> logout() async {
    await _authRepo.signOut();
    state = null;
  }

  Future<void> updateDisplayName(String displayName) async {
    if (state == null) return;
    await _authRepo.updateDisplayName(state!.uid, displayName);
    state = state!.copyWith(displayName: displayName);
  }

  Future<void> updateIncome(double income) async {
    if (state == null) return;
    await _authRepo.updateMonthlyIncome(state!.uid, income);
    state = state!.copyWith(monthlyIncome: income);
  }
}
