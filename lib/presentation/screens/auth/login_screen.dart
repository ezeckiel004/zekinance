import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez remplir tous les champs')),
      );
      return;
    }

    ref.read(authStateProvider.notifier).login(email, password);
    context.go('/dashboard');
  }

  void _handleMockQuickLogin() {
    ref.read(authStateProvider.notifier).login('contact@zekinance.com', 'password');
    context.go('/dashboard');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBg,
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
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.trending_up_rounded,
                      color: AppColors.primary,
                      size: 28,
                    ),
                  ),
                  TextButton(
                    onPressed: _handleMockQuickLogin,
                    child: const Text(
                      'Accès Rapide',
                      style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ).animate().fadeIn(duration: 500.ms),

              const SizedBox(height: 40),

              // Title
              Text(
                'Bon retour !',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1, end: 0),

              const SizedBox(height: 8),

              // Subtitle
              Text(
                'Connectez-vous pour suivre et optimiser vos finances.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.darkTextSecondary,
                ),
              ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1, end: 0),

              const SizedBox(height: 40),

              // Email Input
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Adresse Email',
                  prefixIcon: Icon(Icons.email_outlined, color: AppColors.darkTextSecondary),
                  hintText: 'exemple@domaine.com',
                ),
              ).animate().fadeIn(delay: 300.ms),

              const SizedBox(height: 20),

              // Password Input
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: 'Mot de passe',
                  prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppColors.darkTextSecondary),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      color: AppColors.darkTextSecondary,
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
                  child: const Text(
                    'Mot de passe oublié ?',
                    style: TextStyle(color: AppColors.darkTextSecondary),
                  ),
                ),
              ).animate().fadeIn(delay: 450.ms),

              const SizedBox(height: 24),

              // Login Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _handleLogin,
                  child: const Text('Se Connecter'),
                ),
              ).animate().fadeIn(delay: 500.ms),

              const SizedBox(height: 24),

              // Divider
              Row(
                children: [
                  const Expanded(child: Divider(color: AppColors.darkBorder)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'OU CONTINUER AVEC',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.darkTextSecondary,
                      ),
                    ),
                  ),
                  const Expanded(child: Divider(color: AppColors.darkBorder)),
                ],
              ).animate().fadeIn(delay: 550.ms),

              const SizedBox(height: 24),

              // Google Login Button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _handleMockQuickLogin,
                  icon: const Icon(Icons.g_mobiledata_rounded, size: 30, color: Colors.white),
                  label: const Text('Continuer avec Google'),
                ),
              ).animate().fadeIn(delay: 600.ms),

              const SizedBox(height: 32),

              // Sign Up Link
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Nouveau sur FinSmart ? ',
                    style: TextStyle(color: AppColors.darkTextSecondary),
                  ),
                  GestureDetector(
                    onTap: () => context.push('/auth/register'),
                    child: const Text(
                      "S'inscrire",
                      style: TextStyle(
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
