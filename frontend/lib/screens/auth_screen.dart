import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import '../theme/app_theme.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoginMode = true;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _toggleMode() {
    setState(() {
      _isLoginMode = !_isLoginMode;
    });
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();

    if (_isLoginMode) {
      context.read<AuthBloc>().add(
            AuthLoginRequested(
              username: username,
              password: password,
            ),
          );
    } else {
      final email = _emailController.text.trim();
      context.read<AuthBloc>().add(
            AuthRegisterRequested(
              email: email,
              username: username,
              password: password,
            ),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: BlocConsumer<AuthBloc, AuthState>(
          listener: (context, state) {
            developer.log('AuthScreen listener: state changed to ${state.runtimeType}', name: 'AuthScreen');
            if (state is AuthAuthenticated) {
              developer.log('AuthScreen: User authenticated, navigating to HomeScreen', name: 'AuthScreen');
              // Navigation is handled by _AuthGate in main.dart
              // This screen will be automatically replaced
            } else if (state is AuthError) {
              developer.log('AuthScreen: Error occurred: ${state.message}', name: 'AuthScreen');
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: AppTheme.errorColor,
                ),
              );
            } else if (state is AuthUnauthenticated && state.reason != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.reason!)),
              );
            }
          },
          builder: (context, state) {
            final isLoading = state is AuthLoading;
            final message =
                state is AuthLoading ? state.message ?? 'Please wait...' : null;

            return Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppTheme.spacingL),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: AppTheme.spacingXXL),
                      _buildHeader(context),
                      const SizedBox(height: AppTheme.spacingXL),
                      if (message != null)
                        Container(
                          padding: const EdgeInsets.all(AppTheme.spacingM),
                          decoration: BoxDecoration(
                            color: AppTheme.infoColor.withOpacity(0.1),
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusM),
                          ),
                          child: Row(
                            children: [
                              const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                              const SizedBox(width: AppTheme.spacingM),
                              Expanded(
                                child: Text(
                                  message,
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: AppTheme.spacingL),
                      _buildForm(isLoading),
                      const SizedBox(height: AppTheme.spacingL),
                      _buildToggle(),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                AppTheme.primaryColor,
                AppTheme.secondaryColor,
              ],
            ),
            borderRadius: BorderRadius.circular(AppTheme.radiusL),
            boxShadow: AppTheme.elevatedShadow,
          ),
          child: const Icon(
            Icons.auto_awesome,
            size: 36,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: AppTheme.spacingM),
        Text(
          'Welcome to ARIA',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: AppTheme.spacingXS),
        Text(
          _isLoginMode
              ? 'Sign in to access your prioritization workspace'
              : 'Create an account to start prioritizing requirements',
          style: Theme.of(context).textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildForm(bool isLoading) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!_isLoginMode) ...[
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.email_outlined),
              ),
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Email is required';
                }
                if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value.trim())) {
                  return 'Enter a valid email address';
                }
                return null;
              },
            ),
            const SizedBox(height: AppTheme.spacingM),
          ],
          TextFormField(
            controller: _usernameController,
            decoration: const InputDecoration(
              labelText: 'Username',
              prefixIcon: Icon(Icons.person_outline),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Username is required';
              }
              if (value.trim().length < 3) {
                return 'Username must be at least 3 characters';
              }
              return null;
            },
          ),
          const SizedBox(height: AppTheme.spacingM),
          TextFormField(
            controller: _passwordController,
            decoration: InputDecoration(
              labelText: 'Password',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
              ),
            ),
            obscureText: _obscurePassword,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Password is required';
              }
              if (value.trim().length < 6) {
                return 'Password must be at least 6 characters';
              }
              return null;
            },
          ),
          const SizedBox(height: AppTheme.spacingL),
          ElevatedButton(
            onPressed: isLoading ? null : _submit,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingM),
              child: Text(
                _isLoginMode ? 'Sign In' : 'Create Account',
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggle() {
    return Column(
      children: [
        Text(
          _isLoginMode ? 'Need an account?' : 'Already registered?',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        TextButton(
          onPressed: _toggleMode,
          child: Text(_isLoginMode ? 'Create Account' : 'Sign In'),
        ),
      ],
    );
  }
}

