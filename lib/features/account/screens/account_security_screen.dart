import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:voyanz/core/providers/language_provider.dart';
import 'package:voyanz/core/theme/app_colors.dart';
import 'package:voyanz/core/theme/widgets.dart';
import 'package:voyanz/features/account/providers/account_provider.dart';
import 'package:voyanz/features/auth/providers/auth_provider.dart';

/// Password, email and account deletion (contracts P4).
///
/// Account deletion must be reachable from inside the app for every account
/// that can be created in it (App Store guideline 5.1.1(v)).
class AccountSecurityScreen extends ConsumerStatefulWidget {
  const AccountSecurityScreen({super.key});

  @override
  ConsumerState<AccountSecurityScreen> createState() =>
      _AccountSecurityScreenState();
}

class _AccountSecurityScreenState extends ConsumerState<AccountSecurityScreen> {
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  bool _savingPassword = false;
  bool _savingEmail = false;
  bool _deleting = false;

  @override
  void dispose() {
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  void _toast(String message, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? AppColors.error : AppColors.online,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _clean(Object error) =>
      error.toString().replaceFirst(RegExp(r'^Exception:\s*'), '').trim();

  Future<void> _savePassword() async {
    final t = ref.read(translationsProvider);
    final password = _passwordCtrl.text.trim();
    final confirm = _confirmCtrl.text.trim();
    if (password.isEmpty) return _toast(t.passwordRequired, error: true);
    if (password != confirm) {
      return _toast(t.passwordsDoNotMatch, error: true);
    }

    final coId = ref.read(authStateProvider).valueOrNull?.coId;
    if (coId == null) return;

    setState(() => _savingPassword = true);
    try {
      await ref
          .read(accountRepositoryProvider)
          .changePassword(coId, password, confirm);
      _passwordCtrl.clear();
      _confirmCtrl.clear();
      _toast(t.passwordUpdated);
    } catch (e) {
      _toast(_clean(e), error: true);
    } finally {
      if (mounted) setState(() => _savingPassword = false);
    }
  }

  Future<void> _saveEmail() async {
    final t = ref.read(translationsProvider);
    final email = _emailCtrl.text.trim();
    if (email.isEmpty) return _toast(t.emailRequired, error: true);

    final coId = ref.read(authStateProvider).valueOrNull?.coId;
    if (coId == null) return;

    setState(() => _savingEmail = true);
    try {
      await ref.read(accountRepositoryProvider).changeEmail(coId, email);
      await ref.read(authStateProvider.notifier).refreshUser();
      _emailCtrl.clear();
      _toast(t.emailUpdated);
    } catch (e) {
      _toast(_clean(e), error: true);
    } finally {
      if (mounted) setState(() => _savingEmail = false);
    }
  }

  Future<void> _deleteAccount() async {
    final t = ref.read(translationsProvider);
    final user = ref.read(authStateProvider).valueOrNull;
    if (user == null) return;

    final warning = user.isProfessional
        ? t.deleteAccountProWarning
        : t.deleteAccountCustomerWarning;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceCard,
        title: Text(
          t.deleteAccountConfirm,
          style: GoogleFonts.jost(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        content: Text(
          warning,
          style: GoogleFonts.montserrat(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(t.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              t.deleteAccount,
              style: const TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _deleting = true);
    try {
      final requested = await ref
          .read(accountRepositoryProvider)
          .deleteAccount(user.coId);
      if (!mounted) return;
      _toast(requested ? t.accountDeletionRequested : t.accountDeleted);
      // The server already logged this account out.
      await ref.read(authStateProvider.notifier).logout();
      if (!mounted) return;
      context.go('/login');
    } catch (e) {
      final message = _clean(e);
      _toast(
        message.contains('account_deletion_in_session')
            ? t.accountDeletionInSession
            : message,
        error: true,
      );
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = ref.watch(translationsProvider);
    final user = ref.watch(authStateProvider).valueOrNull;

    return GradientScaffold(
      appBar: VoyanzAppBar(
        title: Text(
          t.accountSecurity,
          style: GoogleFonts.lora(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          children: [
            _Section(
              title: t.changePassword,
              children: [
                TextField(
                  controller: _passwordCtrl,
                  obscureText: true,
                  decoration: InputDecoration(labelText: t.newPassword),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _confirmCtrl,
                  obscureText: true,
                  decoration: InputDecoration(labelText: t.confirmPassword),
                ),
                const SizedBox(height: 14),
                _SaveButton(
                  label: t.save,
                  busy: _savingPassword,
                  onPressed: _savePassword,
                ),
              ],
            ),
            const SizedBox(height: 20),
            _Section(
              title: t.changeEmail,
              children: [
                if ((user?.email ?? '').isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Text(
                      user!.email!,
                      style: GoogleFonts.montserrat(
                        fontSize: 13,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ),
                TextField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(labelText: t.newEmail),
                ),
                const SizedBox(height: 14),
                _SaveButton(
                  label: t.save,
                  busy: _savingEmail,
                  onPressed: _saveEmail,
                ),
              ],
            ),
            const SizedBox(height: 20),
            _Section(
              title: t.deleteAccount,
              danger: true,
              children: [
                Text(
                  user?.isProfessional == true
                      ? t.deleteAccountProWarning
                      : t.deleteAccountCustomerWarning,
                  style: GoogleFonts.montserrat(
                    fontSize: 13,
                    height: 1.45,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _deleting ? null : _deleteAccount,
                    icon: _deleting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.delete_outline),
                    label: Text(t.deleteAccount),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: const BorderSide(color: AppColors.error),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final List<Widget> children;
  final bool danger;

  const _Section({
    required this.title,
    required this.children,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: danger
              ? AppColors.error.withValues(alpha: 0.5)
              : AppColors.borderSubtle,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.jost(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: danger ? AppColors.error : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }
}

class _SaveButton extends StatelessWidget {
  final String label;
  final bool busy;
  final VoidCallback onPressed;

  const _SaveButton({
    required this.label,
    required this.busy,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: busy ? null : onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.mediumPurple,
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
        child: busy
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Text(label),
      ),
    );
  }
}
