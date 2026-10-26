import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../shared/providers/auth_provider.dart';

/// Sign-out is real (clears secure storage + resets auth state) even
/// though the sign-in path is still mock — Day 3 §35 rule applies equally
/// to logout: no fake buttons.
class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).user;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          ListTile(
            leading: const CircleAvatar(child: Icon(Icons.person)),
            title: Text(user?.displayName ?? 'Guest'),
            subtitle: Text(user?.role.name ?? ''),
          ),
          const Divider(height: AppSpacing.xxxl),
          const ListTile(
            leading: Icon(Icons.shield_outlined),
            title: Text('Consent & data access'),
            subtitle: Text('Coming in the next implementation phase'),
            enabled: false,
          ),
          const ListTile(
            leading: Icon(Icons.language_outlined),
            title: Text('Language'),
            subtitle: Text('English · हिन्दी coming soon'),
            enabled: false,
          ),
          const Divider(height: AppSpacing.xxxl),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Sign out'),
            onTap: () => ref.read(authStateProvider.notifier).signOut(),
          ),
        ],
      ),
    );
  }
}
