import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_routes.dart';
import '../../../../models/user_role.dart';
import '../../../../utils/snackbar_utils.dart';
import '../../../../utils/validators.dart';
import '../../../../widgets/common/app_text_field.dart';
import '../../../../widgets/common/primary_button.dart';
import '../providers/auth_provider.dart';

class TechnicianRegisterScreen extends ConsumerStatefulWidget {
  const TechnicianRegisterScreen({super.key});

  @override
  ConsumerState<TechnicianRegisterScreen> createState() =>
      _TechnicianRegisterScreenState();
}

class _TechnicianRegisterScreenState
    extends ConsumerState<TechnicianRegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  // Technician-specific
  String? _selectedSpecialty;
  final List<String> _specialties = [
    'Hardware',
    'Software',
    'Network',
    'Security',
    'Database',
    'General IT',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedSpecialty == null) {
      showAppSnackBar(context, message: 'Please select your specialty', isError: true);
      return;
    }

    try {
      await ref.read(authControllerProvider.notifier).signUp(
            email: _emailController.text,
            password: _passwordController.text,
            fullName: _nameController.text,
            department: _selectedSpecialty,
            phone: _phoneController.text.isNotEmpty ? _phoneController.text : null,
            role: UserRole.technician,
          );
      if (mounted) {
        showAppSnackBar(context, message: 'Welcome! Your technician account is ready.');
        context.go(AppRoutes.technicianDashboard);
      }
    } catch (e) {
      if (mounted) {
        showAppSnackBar(context, message: getErrorMessage(e), isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLoading = ref.watch(authControllerProvider).isLoading;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Back button
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    onPressed: () => context.pop(),
                    icon: const Icon(Icons.arrow_back),
                    padding: EdgeInsets.zero,
                  ),
                ).animate().fadeIn(),

                const SizedBox(height: 8),

                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        Icons.build_circle_outlined,
                        size: 32,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Join as Technician',
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              )),
                          Text('IT Support Team',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.outline,
                              )),
                        ],
                      ),
                    ),
                  ],
                ).animate().fadeIn(delay: 100.ms),

                const SizedBox(height: 32),

                // Personal info section
                _SectionLabel(label: 'Personal Information', icon: Icons.person_outline),
                const SizedBox(height: 12),

                AppTextField(
                  controller: _nameController,
                  label: 'Full Name',
                  hint: 'John Smith',
                  prefixIcon: Icons.person_outline,
                  textInputAction: TextInputAction.next,
                  validator: (v) => Validators.required(v, fieldName: 'Full name'),
                ).animate().fadeIn(delay: 150.ms),
                const SizedBox(height: 16),

                AppTextField(
                  controller: _emailController,
                  label: 'Work Email',
                  hint: 'tech@company.com',
                  prefixIcon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  autocorrect: false,
                  validator: Validators.email,
                ).animate().fadeIn(delay: 200.ms),
                const SizedBox(height: 16),

                AppTextField(
                  controller: _phoneController,
                  label: 'Phone Number',
                  hint: '+66 XX XXX XXXX',
                  prefixIcon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                  validator: Validators.phone,
                ).animate().fadeIn(delay: 250.ms),

                const SizedBox(height: 24),

                // Specialty section
                _SectionLabel(label: 'Technical Specialty', icon: Icons.construction_outlined),
                const SizedBox(height: 12),

                _SpecialtySelector(
                  selected: _selectedSpecialty,
                  specialties: _specialties,
                  onSelected: (v) => setState(() => _selectedSpecialty = v),
                ).animate().fadeIn(delay: 300.ms),

                const SizedBox(height: 24),

                // Password section
                _SectionLabel(label: 'Security', icon: Icons.lock_outline),
                const SizedBox(height: 12),

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
                    icon: Icon(_obscurePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ).animate().fadeIn(delay: 350.ms),
                const SizedBox(height: 16),

                AppTextField(
                  controller: _confirmPasswordController,
                  label: 'Confirm Password',
                  prefixIcon: Icons.lock_outline,
                  obscureText: _obscureConfirm,
                  textInputAction: TextInputAction.done,
                  autocorrect: false,
                  onFieldSubmitted: (_) => _handleRegister(),
                  validator: (v) =>
                      Validators.confirmPassword(v, _passwordController.text),
                  suffixIcon: IconButton(
                    icon: Icon(_obscureConfirm
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined),
                    onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                  ),
                ).animate().fadeIn(delay: 400.ms),

                const SizedBox(height: 32),

                PrimaryButton(
                  label: 'Create Technician Account',
                  isLoading: isLoading,
                  icon: Icons.build_circle_outlined,
                  onPressed: _handleRegister,
                ).animate().fadeIn(delay: 450.ms),

                const SizedBox(height: 16),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Already have an account?',
                        style: theme.textTheme.bodyMedium),
                    TextButton(
                      onPressed: isLoading ? null : () => context.pop(),
                      child: const Text('Sign In'),
                    ),
                  ],
                ).animate().fadeIn(delay: 500.ms),

                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label, required this.icon});
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 16, color: theme.colorScheme.primary),
        const SizedBox(width: 8),
        Text(label,
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w600,
            )),
      ],
    );
  }
}

class _SpecialtySelector extends StatelessWidget {
  const _SpecialtySelector({
    required this.selected,
    required this.specialties,
    required this.onSelected,
  });

  final String? selected;
  final List<String> specialties;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: specialties.map((s) {
        final isSelected = s == selected;
        return FilterChip(
          label: Text(s),
          selected: isSelected,
          onSelected: (_) => onSelected(s),
          showCheckmark: true,
        );
      }).toList(),
    );
  }
}


