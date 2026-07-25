import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() {
    return _ForgotPasswordScreenState();
  }
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _emailController = TextEditingController();

  bool _emailSent = false;
  String _submittedEmail = '';

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    final email = _emailController.text.trim();

    final success = await context.read<AuthProvider>().sendPasswordResetEmail(
      email: email,
    );

    if (!mounted) {
      return;
    }

    if (success) {
      setState(() {
        _emailSent = true;
        _submittedEmail = email;
      });

      return;
    }

    final authProvider = context.read<AuthProvider>();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          authProvider.errorMessage ?? 'Unable to send reset instructions.',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.lightBackground,
              Color(0xFFEAF3DD),
              Color(0xFFF7EFDF),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 18, 24, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Material(
                      color: Colors.white.withValues(alpha: 0.78),
                      borderRadius: BorderRadius.circular(18),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(18),
                        onTap: () {
                          context.go('/login');
                        },
                        child: const SizedBox(
                          width: 49,
                          height: 49,
                          child: Icon(Icons.arrow_back_rounded),
                        ),
                      ),
                    ),
                    const Spacer(),
                    const Text(
                      'Aurora',
                      style: TextStyle(
                        color: AppColors.primaryDark,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 55),

                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 350),
                  child: _emailSent
                      ? _ResetEmailSent(
                          key: const ValueKey('email-sent'),
                          email: _submittedEmail,
                          onUseAnotherEmail: () {
                            setState(() {
                              _emailSent = false;
                            });
                          },
                        )
                      : Form(
                          key: const ValueKey('reset-form'),
                          child: _ResetPasswordForm(
                            formKey: _formKey,
                            emailController: _emailController,
                            isLoading: authProvider.isLoading,
                            onSubmit: _submit,
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ResetPasswordForm extends StatelessWidget {
  const _ResetPasswordForm({
    required this.formKey,
    required this.emailController,
    required this.isLoading,
    required this.onSubmit,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;
  final bool isLoading;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 74,
            height: 74,
            decoration: BoxDecoration(
              color: AppColors.accentPurple,
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                  color: AppColors.accentPurple.withValues(alpha: 0.22),
                  blurRadius: 28,
                  offset: const Offset(0, 14),
                ),
              ],
            ),
            child: const Icon(
              Icons.lock_reset_rounded,
              color: Colors.white,
              size: 38,
            ),
          ),

          const SizedBox(height: 30),

          Text(
            'Forgot your\npassword?',
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
              fontSize: 39,
              height: 1.1,
              fontWeight: FontWeight.w800,
              letterSpacing: -1.2,
            ),
          ),

          const SizedBox(height: 14),

          const Text(
            'Enter the email associated with your '
            'Aurora account. We will send instructions '
            'for creating a new password.',
            style: TextStyle(
              color: AppColors.lightTextSecondary,
              fontSize: 16,
              height: 1.55,
            ),
          ),

          const SizedBox(height: 36),

          TextFormField(
            controller: emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) {
              onSubmit();
            },
            decoration: const InputDecoration(
              labelText: 'Email address',
              prefixIcon: Icon(Icons.mail_outline_rounded),
            ),
            validator: (value) {
              final email = value?.trim() ?? '';

              if (email.isEmpty) {
                return 'Enter your email address.';
              }

              final valid = RegExp(
                r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
              ).hasMatch(email);

              if (!valid) {
                return 'Enter a valid email address.';
              }

              return null;
            },
          ),

          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            height: 58,
            child: FilledButton(
              onPressed: isLoading ? null : onSubmit,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primaryDark,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(22),
                ),
              ),
              child: isLoading
                  ? const SizedBox(
                      width: 23,
                      height: 23,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Send reset instructions',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
            ),
          ),

          const SizedBox(height: 20),

          Center(
            child: TextButton.icon(
              onPressed: () {
                context.go('/login');
              },
              icon: const Icon(Icons.arrow_back_rounded),
              label: const Text('Back to sign in'),
            ),
          ),
        ],
      ),
    );
  }
}

class _ResetEmailSent extends StatelessWidget {
  const _ResetEmailSent({
    required this.email,
    required this.onUseAnotherEmail,
    super.key,
  });

  final String email;
  final VoidCallback onUseAnotherEmail;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 82,
          height: 82,
          decoration: BoxDecoration(
            color: AppColors.safe,
            borderRadius: BorderRadius.circular(27),
            boxShadow: [
              BoxShadow(
                color: AppColors.safe.withValues(alpha: 0.22),
                blurRadius: 30,
                offset: const Offset(0, 15),
              ),
            ],
          ),
          child: const Icon(
            Icons.mark_email_read_rounded,
            color: Colors.white,
            size: 41,
          ),
        ),

        const SizedBox(height: 31),

        Text(
          'Check your\nemail.',
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
            fontSize: 39,
            height: 1.1,
            fontWeight: FontWeight.w800,
            letterSpacing: -1.2,
          ),
        ),

        const SizedBox(height: 14),

        Text(
          'Password reset instructions were sent to:',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: AppColors.lightTextSecondary,
            height: 1.5,
          ),
        ),

        const SizedBox(height: 13),

        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(17),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.78),
            borderRadius: BorderRadius.circular(21),
          ),
          child: Row(
            children: [
              const Icon(Icons.mail_rounded, color: AppColors.primaryDark),
              const SizedBox(width: 11),
              Expanded(
                child: Text(
                  email,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        Container(
          padding: const EdgeInsets.all(17),
          decoration: BoxDecoration(
            color: AppColors.primaryLight.withValues(alpha: 0.42),
            borderRadius: BorderRadius.circular(21),
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline_rounded, color: AppColors.primaryDark),
              SizedBox(width: 11),
              Expanded(
                child: Text(
                  'The email may take a few moments to '
                  'arrive. Check your spam folder when '
                  'you cannot find it.',
                  style: TextStyle(
                    color: AppColors.lightTextSecondary,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 27),

        SizedBox(
          width: double.infinity,
          height: 58,
          child: FilledButton(
            onPressed: () {
              context.go('/login');
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primaryDark,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(22),
              ),
            ),
            child: const Text(
              'Return to sign in',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
          ),
        ),

        const SizedBox(height: 12),

        SizedBox(
          width: double.infinity,
          height: 55,
          child: OutlinedButton(
            onPressed: onUseAnotherEmail,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primaryDark,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(21),
              ),
            ),
            child: const Text(
              'Use another email address',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ),
      ],
    );
  }
}
