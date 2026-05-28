import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_routes.dart';
import '../../../../utils/snackbar_utils.dart';
import '../../../../utils/validators.dart';
import '../../../../widgets/common/app_text_field.dart';
import '../../../../widgets/common/primary_button.dart';
import '../providers/auth_provider.dart';

/// Registration screen for new employee accounts.
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _departmentController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _departmentController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      await ref.read(authControllerProvider.notifier).signUp(
            email: _emailController.text,
            password: _passwordController.text,
            fullName: _nameController.text,
            department: _departmentController.text.isNotEmpty
                ? _departmentController.text
                : null,
            phone: _phoneController.text.isNotEmpty
                ? _phoneController.text
                : null,
          );
      if (mounted) {
        showAppSnackBar(
          context,
          message: 'Account created successfully! Welcome aboard.',
        );
        context.go(AppRoutes.dashboard);
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
    final authState = ref.watch(authControllerProvider);
    final isLoading = authState.isLoading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Account'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Register as Employee',
                  style: theme.textTheme.headlineSmall,
                ).animate().fadeIn(),
                const SizedBox(height: 8),
                Text(
                  'Fill in your details to request IT support',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                ).animate().fadeIn(delay: 100.ms),
                const SizedBox(height: 32),

                AppTextField(
                  controller: _nameController,
                  label: 'Full Name',
                  hint: 'John Smith',
                  prefixIcon: Icons.person_outline,
                  textInputAction: TextInputAction.next,
                  validator: (v) => Validators.required(v, fieldName: 'Full name'),
                ).animate().fadeIn(delay: 200.ms),
                const SizedBox(height: 16),

                AppTextField(
                  controller: _emailController,
                  label: 'Work Email',
                  hint: 'you@company.com',
                  prefixIcon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  autocorrect: false,
                  validator: Validators.email,
                ).animate().fadeIn(delay: 250.ms),
                const SizedBox(height: 16),

                AppTextField(
                  controller: _departmentController,
                  label: 'Department (Optional)',
                  hint: 'e.g. Operations, Finance',
                  prefixIcon: Icons.business_outlined,
                  textInputAction: TextInputAction.next,
                ).animate().fadeIn(delay: 300.ms),
                const SizedBox(height: 16),

                AppTextField(
                  controller: _phoneController,
                  label: 'Phone (Optional)',
                  hint: '+66 XX XXX XXXX',
                  prefixIcon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                  validator: Validators.phone,
                ).animate().fadeIn(delay: 350.ms),
                const SizedBox(height: 16),

                AppTextField(
                  controller: _passwordController,
                  label: 'Password',
                  hint: 'Minimum 6 characters',
                  prefixIcon: Icons.lock_outline,
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.next,
                  autocorrect: false,
                  validator: Validators.password,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                    onPressed: () {
                      setState(() => _obscurePassword = !_obscurePassword);
                    },
                  ),
                ).animate().fadeIn(delay: 400.ms),
                const SizedBox(height: 16),

                AppTextField(
                  controller: _confirmPasswordController,
                  label: 'Confirm Password',
                  prefixIcon: Icons.lock_outline,
                  obscureText: _obscureConfirm,
                  textInputAction: TextInputAction.done,
                  autocorrect: false,
                  validator: (v) => Validators.confirmPassword(
                    v,
                    _passwordController.text,
                  ),
                  onFieldSubmitted: (_) => _handleRegister(),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirm
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                    onPressed: () {
                      setState(() => _obscureConfirm = !_obscureConfirm);
                    },
                  ),
                ).animate().fadeIn(delay: 450.ms),
                const SizedBox(height: 32),

                PrimaryButton(
                  label: 'Create Account',
                  isLoading: isLoading,
                  icon: Icons.person_add_outlined,
                  onPressed: _handleRegister,
                ).animate().fadeIn(delay: 500.ms),
                const SizedBox(height: 16),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Already have an account?',
                      style: theme.textTheme.bodyMedium,
                    ),
                    TextButton(
                      onPressed: isLoading ? null : () => context.pop(),
                      child: const Text('Sign In'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
