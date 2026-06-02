import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../providers/settings_provider.dart';
import '../../../app/theme/app_colors.dart';
import '../../widgets/ze_kinance_logo.dart';
import '../../../core/localization/translations.dart';

class BiometricLockWrapper extends ConsumerStatefulWidget {
  final Widget child;

  const BiometricLockWrapper({super.key, required this.child});

  @override
  ConsumerState<BiometricLockWrapper> createState() => _BiometricLockWrapperState();
}

class _BiometricLockWrapperState extends ConsumerState<BiometricLockWrapper> with WidgetsBindingObserver {
  bool _isLocked = false;
  final LocalAuthentication _auth = LocalAuthentication();
  bool _isAuthenticating = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkLockOnStart();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  bool get _isUserConnected => FirebaseAuth.instance.currentUser != null;

  Future<void> _checkLockOnStart() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isEnabled = prefs.getBool(kBiometricsKey) ?? false;
      if (isEnabled && _isUserConnected && mounted) {
        setState(() {
          _isLocked = true;
        });
        _authenticate();
      }
    } catch (_) {}
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_isUserConnected) {
      if (_isLocked) {
        setState(() => _isLocked = false);
      }
      return;
    }

    if (state == AppLifecycleState.resumed) {
      if (_isAuthenticating) return; // Ignore if we just returned from auth
      
      final isEnabled = ref.read(biometricsProvider);
      if (isEnabled && !_isLocked) {
        setState(() {
          _isLocked = true;
        });
        _authenticate();
      }
    } else if (state == AppLifecycleState.paused) {
      if (_isAuthenticating) return; // Do not lock if pausing due to auth
      
      final isEnabled = ref.read(biometricsProvider);
      if (isEnabled) {
         setState(() {
           _isLocked = true;
         });
      }
    }
  }

  Future<void> _authenticate() async {
    if (_isAuthenticating) return;
    _isAuthenticating = true;
    
    try {
      final lang = ref.read(languageProvider);
      final bool authenticated = await _auth.authenticate(
        localizedReason: Translations.getText(lang, 'auth_reason'),
        options: const AuthenticationOptions(
          biometricOnly: false,
          stickyAuth: true,
        ),
      );

      if (authenticated && mounted) {
        setState(() {
          _isLocked = false;
        });
      }
    } catch (e) {
      debugPrint("Auth Error: $e");
    } finally {
      // Delay resetting to prevent the resumed event from re-triggering the lock
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          _isAuthenticating = false;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(languageProvider);
    
    return Stack(
      textDirection: TextDirection.ltr,
      children: [
        widget.child,
        if (_isLocked)
          Positioned.fill(
            child: Directionality(
              textDirection: TextDirection.ltr,
              child: Scaffold(
                backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                body: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const ZeKinanceLogo(size: 100),
                      const SizedBox(height: 40),
                      const Icon(Icons.lock_rounded, size: 48, color: AppColors.primary),
                      const SizedBox(height: 20),
                      Text(
                        lang == 'fr' ? 'Application verrouillée' : 'App Locked',
                        style: TextStyle(
                          fontSize: 20, 
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).brightness == Brightness.dark ? Colors.white : AppColors.lightTextPrimary,
                        ),
                      ),
                      const SizedBox(height: 40),
                      ElevatedButton.icon(
                        onPressed: _authenticate,
                        icon: const Icon(Icons.fingerprint_rounded, color: Colors.black),
                        label: Text(
                          lang == 'fr' ? 'Déverrouiller' : 'Unlock', 
                          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
