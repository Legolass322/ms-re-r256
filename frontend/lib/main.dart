import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api/aria_api_client.dart';
import 'bloc/auth_bloc.dart';
import 'bloc/auth_event.dart';
import 'bloc/auth_state.dart';
import 'bloc/requirements_bloc.dart';
import 'bloc/requirements_event.dart';
import 'repositories/auth_repository.dart';
import 'screens/auth_screen.dart';
import 'screens/home_screen.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final preferences = await SharedPreferences.getInstance();
  final apiClient = AriaApiClient();
  final authRepository = AuthRepository(
    apiClient: apiClient,
    preferences: preferences,
  );

  runApp(
    AriaApp(
      apiClient: apiClient,
      authRepository: authRepository,
    ),
  );
}

class AriaApp extends StatelessWidget {
  const AriaApp({
    super.key,
    required this.apiClient,
    required this.authRepository,
  });

  final AriaApiClient apiClient;
  final AuthRepository authRepository;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AriaApiClient>.value(value: apiClient),
        BlocProvider(
          create: (context) => AuthBloc(authRepository: authRepository)
            ..add(const AuthStarted()),
        ),
        BlocProvider(
          create: (context) => RequirementsBloc(apiClient: apiClient),
        ),
      ],
      child: MaterialApp(
        title: 'ARIA',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        builder: (context, child) {
          return BlocListener<AuthBloc, AuthState>(
            listener: (context, state) {
              if (state is AuthAuthenticated) {
                // Restore latest session when user authenticates
                context
                    .read<RequirementsBloc>()
                    .add(const RestoreLatestSessionEvent());
              } else if (state is AuthUnauthenticated) {
                // Reset requirements when user logs out
                context.read<RequirementsBloc>().add(const ResetEvent());
              }
            },
            child: child,
          );
        },
        home: const _AuthGate(),
      ),
    );
  }
}

class _AuthGate extends StatelessWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        developer.log('DEBUG: _AuthGate listener: state changed to ${state.runtimeType}', name: '_AuthGate');
        if (state is AuthAuthenticated) {
          developer.log('DEBUG: _AuthGate: User authenticated, User: ${state.user.username}, isAdmin: ${state.user.isAdmin}', name: '_AuthGate');
        } else if (state is AuthError) {
          developer.log('DEBUG: _AuthGate: Auth error: ${state.message}', name: '_AuthGate');
        }
      },
      child: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          developer.log('DEBUG: _AuthGate building with state: ${state.runtimeType}', name: '_AuthGate');
          
          if (state is AuthLoading || state is AuthInitial) {
            final message = state is AuthLoading ? state.message : null;
            developer.log('DEBUG: Showing loading screen', name: '_AuthGate');
            return Scaffold(
              body: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(),
                    if (message != null) ...[
                      const SizedBox(height: AppTheme.spacingM),
                      Text(message),
                    ],
                  ],
                ),
              ),
            );
          } else if (state is AuthAuthenticated) {
            // User is authenticated, show home screen
            developer.log('DEBUG: User authenticated, showing HomeScreen. User: ${state.user.username}, isAdmin: ${state.user.isAdmin}', name: '_AuthGate');
            return const HomeScreen();
          } else if (state is AuthError) {
            // Show error and allow retry
            developer.log('DEBUG: Auth error: ${state.message}, showing AuthScreen', name: '_AuthGate');
            return const AuthScreen();
          }
          // Default: show auth screen
          developer.log('DEBUG: Default case, showing AuthScreen', name: '_AuthGate');
          return const AuthScreen();
        },
      ),
    );
  }
}
