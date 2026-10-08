import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/components/app_button.dart';
import '../../../../core/theme/components/app_text_field.dart';
import '../controllers/auth_controller.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _sent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final success = await ref
        .read(authControllerProvider.notifier)
        .sendPasswordReset(_emailController.text);

    if (success && mounted) {
      setState(() {
        _sent = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final isLoading = authState.isLoading;
    final errorMessage = authState.hasError
        ? (authState.error is Failure
            ? (authState.error as Failure).message
            : 'Unable to send reset email. Please try again.')
        : null;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reset Password'),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: AppSpacing.paddingAllLg,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440.0),
              child: _sent
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Icon(
                          Icons.mark_email_read_outlined,
                          size: 64.0,
                          color: AppColors.statusStable,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          'Check Your Inbox',
                          textAlign: TextAlign.center,
                          style: isDark
                              ? AppTypography.headlineLarge.copyWith(color: AppColors.neutral50)
                              : AppTypography.headlineLarge.copyWith(color: AppColors.neutral900),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          'If an account exists for ${_emailController.text}, you will receive a secure link to reset your password.',
                          textAlign: TextAlign.center,
                          style: AppTypography.bodyMedium.copyWith(color: AppColors.neutral500),
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        AppButton(
                          label: 'Back to Sign In',
                          onPressed: () => context.pop(),
                          isFullWidth: true,
                        ),
                      ],
                    )
                  : Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Forgot Your Password?',
                            textAlign: TextAlign.center,
                            style: isDark
                                ? AppTypography.headlineLarge.copyWith(color: AppColors.neutral50)
                                : AppTypography.headlineLarge.copyWith(color: AppColors.neutral900),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            'Enter your registered email address and we will send you a recovery link.',
                            textAlign: TextAlign.center,
                            style: AppTypography.bodyMedium.copyWith(color: AppColors.neutral500),
                          ),
                          const SizedBox(height: AppSpacing.xl),

                          if (errorMessage != null) ...[
                            Container(
                              padding: AppSpacing.paddingAllMd,
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEE2E2),
                                borderRadius: AppSpacing.roundedSm,
                                border: Border.all(color: AppColors.statusUrgent.withAlpha(80)),
                              ),
                              child: Text(
                                errorMessage,
                                style: const TextStyle(
                                  color: Color(0xFF991B1B),
                                  fontSize: 13.0,
                                ),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.lg),
                          ],

                          AppTextField(
                            label: 'Email Address',
                            hintText: 'name@example.com',
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            prefixIcon: const Icon(Icons.email_outlined, size: 20.0),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter your email address.';
                              }
                              if (!value.contains('@') || !value.contains('.')) {
                                return 'Please enter a valid email address.';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: AppSpacing.xl),

                          AppButton(
                            label: 'Send Recovery Link',
                            isLoading: isLoading,
                            onPressed: _submit,
                            isFullWidth: true,
                          ),
                          const SizedBox(height: AppSpacing.md),

                          TextButton(
                            onPressed: () => context.pop(),
                            child: const Text('Back to Sign In'),
                          ),
                        ],
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
