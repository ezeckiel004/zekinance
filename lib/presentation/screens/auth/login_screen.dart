import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/localization/translations.dart';
import '../../widgets/ze_kinance_logo.dart';
import '../../providers/auth_provider.dart';
import '../../providers/settings_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final isFr = ref.read(languageProvider) == 'fr';

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(isFr ? 'Veuillez remplir tous les champs' : 'Please fill in all fields')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await ref.read(authStateProvider.notifier).login(email, password);
      if (mounted) {
        context.go('/dashboard');
      }
    } catch (e) {
      if (mounted) {
        final errMsg = isFr ? 'Erreur de connexion' : 'Login error';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$errMsg: ${e.toString().split(']').last.trim()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _handleMockQuickLogin() {
    ref.read(authStateProvider.notifier).login('contact@zekinance.com', 'password');
    context.go('/dashboard');
  }

  @override
  Widget build(BuildContext context) {
    final isFr = ref.watch(languageProvider) == 'fr';
    
    return Scaffold(
      backgroundColor: context.scaffoldBg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              // App Logo & Back Button Vibe
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const ZeKinanceLogo(size: 48, hasGlow: false),
                  TextButton(
                    onPressed: _handleMockQuickLogin,
                    child: Text(
                      isFr ? 'Accès Rapide' : 'Quick Access',
                      style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ).animate().fadeIn(duration: 500.ms),

              const SizedBox(height: 40),

              // Title
              Text(
                context.tr(ref, 'login_title'),
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                  color: context.textPrimary,
                ),
              ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1, end: 0),

              const SizedBox(height: 8),

              // Subtitle
              Text(
                context.tr(ref, 'login_subtitle'),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: context.textSecondary,
                ),
              ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1, end: 0),

              const SizedBox(height: 40),

              // Email Input
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                style: TextStyle(color: context.textPrimary),
                decoration: InputDecoration(
                  labelText: context.tr(ref, 'email_label'),
                  prefixIcon: Icon(Icons.email_outlined, color: context.textSecondary),
                  hintText: 'exemple@domaine.com',
                ),
              ).animate().fadeIn(delay: 300.ms),

              const SizedBox(height: 20),

              // Password Input
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                style: TextStyle(color: context.textPrimary),
                decoration: InputDecoration(
                  labelText: context.tr(ref, 'password_label'),
                  prefixIcon: Icon(Icons.lock_outline_rounded, color: context.textSecondary),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      color: context.textSecondary,
                    ),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
              ).animate().fadeIn(delay: 400.ms),

              const SizedBox(height: 12),

              // Forgot Password link
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {},
                  child: Text(
                    isFr ? 'Mot de passe oublié ?' : 'Forgot password?',
                    style: TextStyle(color: context.textSecondary),
                  ),
                ),
              ).animate().fadeIn(delay: 450.ms),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleLogin,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                        )
                      : Text(context.tr(ref, 'login_btn')),
                ),
              ).animate().fadeIn(delay: 500.ms),

              const SizedBox(height: 24),

              // Divider
              Row(
                children: [
                  Expanded(child: Divider(color: context.borderColor)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      isFr ? 'OU CONTINUER AVEC' : 'OR CONTINUE WITH',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: context.textSecondary,
                      ),
                    ),
                  ),
                  Expanded(child: Divider(color: context.borderColor)),
                ],
              ).animate().fadeIn(delay: 550.ms),

              const SizedBox(height: 24),

              // Google Login Button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _handleMockQuickLogin,
                  icon: Icon(Icons.g_mobiledata_rounded, size: 30, color: context.textPrimary),
                  label: Text(isFr ? 'Continuer avec Google' : 'Continue with Google', style: TextStyle(color: context.textPrimary)),
                ),
              ).animate().fadeIn(delay: 600.ms),

              const SizedBox(height: 32),

              // Sign Up Link
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    isFr ? 'Nouveau sur Ze Kinance ? ' : 'New to Ze Kinance? ',
                    style: TextStyle(color: context.textSecondary),
                  ),
                  GestureDetector(
                    onTap: () => context.push('/auth/register'),
                    child: Text(
                      isFr ? "S'inscrire" : 'Sign Up',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ).animate().fadeIn(delay: 700.ms),
            ],
          ),
        ),
      ),
    );
  }
}
