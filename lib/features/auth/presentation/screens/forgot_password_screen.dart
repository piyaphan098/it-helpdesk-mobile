import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../utils/snackbar_utils.dart';
import '../../../../utils/validators.dart';
import '../../../../widgets/common/app_text_field.dart';
import '../../../../widgets/common/primary_button.dart';
import '../providers/auth_provider.dart';

/// Forgot password screen — sends reset email via Supabase Auth.
class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _emailSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleResetPassword() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      await ref.read(authControllerProvider.notifier).resetPassword(
            email: _emailController.text,
          );
      if (mounted) {
        setState(() => _emailSent = true);
      }
    } catch (e) {
      if (mounted) {
        showAppSnackBar(
          context,
          message: getErrorMessage(e),
          isError: true,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final authState = ref.watch(authControllerProvider);
    final isLoading = authState.isLoading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reset Password'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: _emailSent ? _buildSuccessView(theme, colorScheme) : _buildFormView(theme, isLoading),
        ),
      ),
    );
  }

  Widget _buildFormView(ThemeData theme, bool isLoading) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(
            Icons.lock_reset,
            size: 64,
            color: theme.colorScheme.primary,
          ).animate().fadeIn().scale(),
          const SizedBox(height: 24),
          Text(
            'Forgot your password?',
            style: theme.textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 100.ms),
          const SizedBox(height: 8),
          Text(
            'Enter your email address and we will send you a link to reset your password.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.outline,
            ),
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 200.ms),
          const SizedBox(height: 32),
          AppTextField(
            controller: _emailController,
            label: 'Email',
            hint: 'you@company.com',
            prefixIcon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            autocorrect: false,
            validator: Validators.email,
            onFieldSubmitted: (_) => _handleResetPassword(),
          ).animate().fadeIn(delay: 300.ms),
          const SizedBox(height: 32),
          PrimaryButton(
            label: 'Send Reset Link',
            isLoading: isLoading,
            icon: Icons.send_outlined,
            onPressed: _handleResetPassword,
          ).animate().fadeIn(delay: 400.ms),
        ],
      ),
    );
  }

  Widget _buildSuccessView(ThemeData theme, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Icon(
          Icons.mark_email_read_outlined,
          size: 64,
          color: colorScheme.primary,
        ).animate().fadeIn().scale(),
        const SizedBox(height: 24),
        Text(
          'Check your email',
          style: theme.textTheme.headlineSmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'We sent a password reset link to ${_emailController.text.trim()}. '
          'Please check your inbox and follow the instructions.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.outline,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        PrimaryButton(
          label: 'Back to Sign In',
          icon: Icons.arrow_back,
          onPressed: () => context.pop(),
        ),
      ],
    ).animate().fadeIn();
  }
}
