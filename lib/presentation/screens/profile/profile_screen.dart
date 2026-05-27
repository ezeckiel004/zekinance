import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../providers/auth_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider);
    final userName = user?.displayName ?? 'Marc Zekinance';
    final userEmail = user?.email ?? 'contact@zekinance.com';
    final userAvatar = user?.photoUrl;

    return Scaffold(
      backgroundColor: AppColors.darkBg,
      appBar: AppBar(
        title: const Text('Mon Profil'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            children: [
              // User Card with avatar and badge
              _buildUserCard(context, userName, userEmail, userAvatar),

              const SizedBox(height: 28),

              // Account & Preferences Section
              _buildPreferencesSection(context, ref),

              const SizedBox(height: 28),

              // Firebase Mode Informer
              _buildFirebaseConnectionCard(context),

              const SizedBox(height: 36),

              // Log Out Button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    ref.read(authStateProvider.notifier).logout();
                    context.go('/auth/login');
                  },
                  icon: const Icon(Icons.logout_rounded, color: AppColors.error),
                  label: const Text(
                    'Se déconnecter',
                    style: TextStyle(color: AppColors.error),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.error),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserCard(BuildContext context, String name, String email, String? avatarUrl) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.darkBorder),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppColors.primaryGradient,
            ),
            child: CircleAvatar(
              radius: 36,
              backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
              backgroundColor: AppColors.darkBg,
              child: avatarUrl == null 
                ? const Icon(Icons.person, color: AppColors.darkTextPrimary, size: 30)
                : null,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      name,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    const SizedBox(width: 8),
                    // Premium badge capsule
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        gradient: AppColors.goldGradient,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'PRO',
                        style: TextStyle(color: Colors.black, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  email,
                  style: TextStyle(color: AppColors.darkTextSecondary, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms);
  }

  Widget _buildPreferencesSection(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.darkBorder),
      ),
      child: Column(
        children: [
          _buildProfileTile(
            icon: Icons.person_outline_rounded,
            color: AppColors.accent,
            title: 'Détails du compte',
            subtitle: 'Modifier vos informations personnelles',
            onTap: () {},
          ),
          _buildDivider(),
          _buildProfileTile(
            icon: Icons.security_rounded,
            color: AppColors.info,
            title: 'Sécurité & Biométrie',
            subtitle: 'Activer le verrouillage par empreinte',
            onTap: () {},
          ),
          _buildDivider(),
          _buildProfileTile(
            icon: Icons.notifications_none_rounded,
            color: AppColors.secondary,
            title: 'Paramètres des notifications',
            subtitle: 'Gérer les alertes budgétaires',
            onTap: () {},
          ),
          _buildDivider(),
          _buildProfileTile(
            icon: Icons.palette_outlined,
            color: AppColors.primary,
            title: 'Mode sombre actif',
            subtitle: 'Le mode sombre premium est activé',
            trailing: Switch(
              value: true,
              activeColor: AppColors.primary,
              onChanged: (val) {},
            ),
            onTap: () {},
          ),
        ],
      ),
    ).animate().fadeIn(delay: 150.ms);
  }

  Widget _buildProfileTile({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    Widget? trailing,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
      subtitle: Text(subtitle, style: const TextStyle(color: AppColors.darkTextSecondary, fontSize: 11)),
      trailing: trailing ?? const Icon(Icons.arrow_forward_ios_rounded, color: AppColors.darkTextSecondary, size: 14),
      onTap: onTap,
    );
  }

  Widget _buildDivider() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: Divider(color: AppColors.darkBorder, height: 1),
    );
  }

  Widget _buildFirebaseConnectionCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.darkSurfaceLight.withOpacity(0.3),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.accent.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.cloud_queue_rounded, color: AppColors.accent, size: 20),
              SizedBox(width: 8),
              Text(
                'Mode de fonctionnement',
                style: TextStyle(color: AppColors.accent, fontSize: 13, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'L\'application fonctionne actuellement en mode **MOCK LOCAL** sécurisé. Vos données sont simulées localement.',
            style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.4),
          ),
          const SizedBox(height: 12),
          const Text(
            'Pour connecter votre propre base Firebase :',
            style: TextStyle(color: AppColors.darkTextSecondary, fontSize: 11, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          const Text(
            '1. Lancez `firebase login`\n2. Configurez avec `flutterfire configure` dans le terminal.',
            style: TextStyle(color: AppColors.darkTextSecondary, fontSize: 11, height: 1.4),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 250.ms);
  }
}
