import 'package:flutter_riverpod/flutter_riverpod.dart';

class MockUser {
  final String uid;
  final String email;
  final String displayName;
  final String? photoUrl;
  
  MockUser({
    required this.uid,
    required this.email,
    required this.displayName,
    this.photoUrl,
  });
}

// Global provider that holds the current user state
final authStateProvider = StateNotifierProvider<AuthNotifier, MockUser?>((ref) {
  return AuthNotifier();
});

class AuthNotifier extends StateNotifier<MockUser?> {
  AuthNotifier() : super(
    // Proactively log in a premium mock user for immediate premium dashboard view
    MockUser(
      uid: 'ze_user_123',
      email: 'contact@zekinance.com',
      displayName: 'Marc Zekinance',
      photoUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb', // Modern placeholder avatar
    ),
  );

  void login(String email, String password) {
    state = MockUser(
      uid: 'ze_user_123',
      email: email,
      displayName: 'Marc Zekinance',
      photoUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb',
    );
  }

  void logout() {
    state = null;
  }
}
