import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/settings_provider.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() {
    return _RegistrationScreenState();
  }
}

class _RegistrationScreenState
    extends State<RegistrationScreen> {
  final GlobalKey<FormState> _formKey =
  GlobalKey<FormState>();

  final TextEditingController _nameController =
  TextEditingController();

  final TextEditingController _emailController =
  TextEditingController();

  final TextEditingController _passwordController =
  TextEditingController();

  final TextEditingController
  _confirmPasswordController =
  TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmation = true;
  bool _acceptedTerms = false;

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!_acceptedTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please accept the Terms and Privacy Policy.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );

      return;
    }

    final authProvider =
    context.read<AuthProvider>();

    final success = await authProvider.register(
      displayName: _nameController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    if (!mounted) {
      return;
    }

    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            authProvider.errorMessage ??
                'Account creation failed.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );

      return;
    }

    await context
        .read<SettingsProvider>()
        .setDisplayName(
      _nameController.text.trim(),
    );

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Your Aurora account was created.',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );

    context.go('/home');
  }

  String? _validateEmail(String? value) {
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
  }

  String? _validatePassword(String? value) {
    final password = value ?? '';

    if (password.length < 8) {
      return 'Use at least 8 characters.';
    }

    if (!RegExp(r'[A-Z]').hasMatch(password)) {
      return 'Include at least one uppercase letter.';
    }

    if (!RegExp(r'[0-9]').hasMatch(password)) {
      return 'Include at least one number.';
    }

    return null;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider =
    context.watch<AuthProvider>();

    return Scaffold(
      body: Container(
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
            padding: const EdgeInsets.fromLTRB(
              24,
              18,
              24,
              32,
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Material(
                        color: Colors.white.withValues(
                          alpha: 0.78,
                        ),
                        borderRadius:
                        BorderRadius.circular(18),
                        child: InkWell(
                          borderRadius:
                          BorderRadius.circular(18),
                          onTap: () {
                            context.go('/login');
                          },
                          child: const SizedBox(
                            width: 49,
                            height: 49,
                            child: Icon(
                              Icons.arrow_back_rounded,
                            ),
                          ),
                        ),
                      ),
                      const Spacer(),
                      const Text(
                        'Aurora',
                        style: TextStyle(
                          color:
                          AppColors.primaryDark,
                          fontSize: 20,
                          fontWeight:
                          FontWeight.w800,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 36),

                  Container(
                    width: 68,
                    height: 68,
                    decoration: BoxDecoration(
                      color: AppColors.primaryDark,
                      borderRadius:
                      BorderRadius.circular(23),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryDark
                              .withValues(
                            alpha: 0.22,
                          ),
                          blurRadius: 26,
                          offset:
                          const Offset(0, 13),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.person_add_rounded,
                      color: Colors.white,
                      size: 34,
                    ),
                  ),

                  const SizedBox(height: 28),

                  Text(
                    'Create your\nAurora account.',
                    style: Theme.of(context)
                        .textTheme
                        .headlineLarge
                        ?.copyWith(
                      fontSize: 38,
                      height: 1.1,
                      fontWeight:
                      FontWeight.w800,
                      letterSpacing: -1.2,
                    ),
                  ),

                  const SizedBox(height: 12),

                  const Text(
                    'Monitor your environment, control devices '
                        'and automate your room from anywhere.',
                    style: TextStyle(
                      color:
                      AppColors.lightTextSecondary,
                      fontSize: 16,
                      height: 1.5,
                    ),
                  ),

                  const SizedBox(height: 32),

                  TextFormField(
                    controller: _nameController,
                    textCapitalization:
                    TextCapitalization.words,
                    textInputAction:
                    TextInputAction.next,
                    decoration:
                    const InputDecoration(
                      labelText: 'Full name',
                      prefixIcon: Icon(
                        Icons.person_outline_rounded,
                      ),
                    ),
                    validator: (value) {
                      if ((value ?? '').trim().length <
                          2) {
                        return 'Enter your full name.';
                      }

                      return null;
                    },
                  ),

                  const SizedBox(height: 15),

                  TextFormField(
                    controller: _emailController,
                    keyboardType:
                    TextInputType.emailAddress,
                    textInputAction:
                    TextInputAction.next,
                    decoration:
                    const InputDecoration(
                      labelText: 'Email address',
                      prefixIcon: Icon(
                        Icons.mail_outline_rounded,
                      ),
                    ),
                    validator: _validateEmail,
                  ),

                  const SizedBox(height: 15),

                  TextFormField(
                    controller:
                    _passwordController,
                    obscureText: _obscurePassword,
                    textInputAction:
                    TextInputAction.next,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(
                        Icons.lock_outline_rounded,
                      ),
                      suffixIcon: IconButton(
                        onPressed: () {
                          setState(() {
                            _obscurePassword =
                            !_obscurePassword;
                          });
                        },
                        icon: Icon(
                          _obscurePassword
                              ? Icons
                              .visibility_off_outlined
                              : Icons
                              .visibility_outlined,
                        ),
                      ),
                    ),
                    validator: _validatePassword,
                  ),

                  const SizedBox(height: 8),

                  const Padding(
                    padding:
                    EdgeInsets.only(left: 8),
                    child: Text(
                      'Use 8+ characters with an uppercase '
                          'letter and a number.',
                      style: TextStyle(
                        color: AppColors
                            .lightTextSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ),

                  const SizedBox(height: 15),

                  TextFormField(
                    controller:
                    _confirmPasswordController,
                    obscureText:
                    _obscureConfirmation,
                    textInputAction:
                    TextInputAction.done,
                    onFieldSubmitted: (_) {
                      _submit();
                    },
                    decoration: InputDecoration(
                      labelText: 'Confirm password',
                      prefixIcon: const Icon(
                        Icons.verified_user_outlined,
                      ),
                      suffixIcon: IconButton(
                        onPressed: () {
                          setState(() {
                            _obscureConfirmation =
                            !_obscureConfirmation;
                          });
                        },
                        icon: Icon(
                          _obscureConfirmation
                              ? Icons
                              .visibility_off_outlined
                              : Icons
                              .visibility_outlined,
                        ),
                      ),
                    ),
                    validator: (value) {
                      if (value !=
                          _passwordController.text) {
                        return 'Passwords do not match.';
                      }

                      return null;
                    },
                  ),

                  const SizedBox(height: 17),

                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(
                        alpha: 0.7,
                      ),
                      borderRadius:
                      BorderRadius.circular(20),
                    ),
                    child: CheckboxListTile(
                      value: _acceptedTerms,
                      controlAffinity:
                      ListTileControlAffinity
                          .leading,
                      contentPadding:
                      const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 4,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                        BorderRadius.circular(20),
                      ),
                      title: const Text(
                        'I agree to the Terms of Service '
                            'and Privacy Policy.',
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.4,
                          fontWeight:
                          FontWeight.w600,
                        ),
                      ),
                      onChanged: (value) {
                        setState(() {
                          _acceptedTerms =
                              value ?? false;
                        });
                      },
                    ),
                  ),

                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    height: 58,
                    child: FilledButton(
                      onPressed:
                      authProvider.isLoading
                          ? null
                          : _submit,
                      style: FilledButton.styleFrom(
                        backgroundColor:
                        AppColors.primaryDark,
                        foregroundColor:
                        Colors.white,
                        shape:
                        RoundedRectangleBorder(
                          borderRadius:
                          BorderRadius.circular(
                            22,
                          ),
                        ),
                      ),
                      child: authProvider.isLoading
                          ? const SizedBox(
                        width: 23,
                        height: 23,
                        child:
                        CircularProgressIndicator(
                          strokeWidth: 2.4,
                          color: Colors.white,
                        ),
                      )
                          : const Row(
                        mainAxisAlignment:
                        MainAxisAlignment
                            .center,
                        children: [
                          Text(
                            'Create account',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight:
                              FontWeight
                                  .w800,
                            ),
                          ),
                          SizedBox(width: 9),
                          Icon(
                            Icons
                                .arrow_forward_rounded,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  Row(
                    mainAxisAlignment:
                    MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Already have an account?',
                        style: TextStyle(
                          color: AppColors
                              .lightTextSecondary,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          context.go('/login');
                        },
                        child: const Text('Sign in'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}