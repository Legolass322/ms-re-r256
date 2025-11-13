import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';

import '../bloc/auth_bloc.dart';
import '../api/aria_api_client.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import '../bloc/requirements_bloc.dart';
import '../bloc/requirements_state.dart';
import '../models/requirement.dart';
import '../theme/app_theme.dart';
import 'requirements_form_screen.dart';
import 'results_screen.dart';
import 'upload_screen.dart';
import 'admin_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: BlocConsumer<RequirementsBloc, RequirementsState>(
          listener: (context, state) {
            if (state is RequirementsError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: AppTheme.errorColor,
                ),
              );
            }
          },
          builder: (context, state) {
            if (state is RequirementsLoading) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(),
                    if (state.message != null) ...[
                      const SizedBox(height: AppTheme.spacingM),
                      Text(state.message!),
                    ],
                  ],
                ),
              );
            }

            final workspace = state is WorkspaceLoaded ? state : null;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(AppTheme.spacingL),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Header(workspace: workspace),
                  const SizedBox(height: AppTheme.spacingXXL),
                  if (workspace != null) ...[
                    _WorkspaceSummary(workspace: workspace),
                    const SizedBox(height: AppTheme.spacingXXL),
                  ],
                  _IntroSection(),
                  const SizedBox(height: AppTheme.spacingXXL),
                  _FeaturesList(),
                  const SizedBox(height: AppTheme.spacingXL),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const UploadScreen(),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          vertical: AppTheme.spacingL,
                        ),
                      ),
                      child: Text(
                        workspace == null ? 'Get Started' : 'New Analysis',
                      ),
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingM),
                  Center(
                    child: Text(
                      'Process up to 100 requirements in under 5 seconds',
                      style: Theme.of(context).textTheme.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingXL),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.workspace});

  final WorkspaceLoaded? workspace;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Expanded(child: _HeaderUserInfo()),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            BlocBuilder<AuthBloc, AuthState>(
              builder: (context, authState) {
                if (authState is AuthAuthenticated && authState.user.isAdmin) {
                  return TextButton.icon(
                    onPressed: () {
                      final apiClient = Provider.of<AriaApiClient>(context, listen: false);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AdminScreen(apiClient: apiClient),
                        ),
                      );
                    },
                    icon: const Icon(Icons.admin_panel_settings),
                    label: const Text('Admin'),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
            if (workspace != null && workspace!.hasRequirements)
              TextButton.icon(
                onPressed: () {
                  final requirements = workspace!.requirements
                      .map((req) => req.copyWith())
                      .toList();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => RequirementsFormScreen(
                        initialRequirements: requirements,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.play_circle_outline),
                label: const Text('Continue'),
              ),
            TextButton.icon(
              onPressed: () {
                context.read<AuthBloc>().add(const AuthLogoutRequested());
              },
              icon: const Icon(Icons.logout),
              label: const Text('Sign Out'),
            ),
          ],
        ),
      ],
    );
  }
}

class _HeaderUserInfo extends StatelessWidget {
  const _HeaderUserInfo();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state is AuthAuthenticated) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hello, ${state.user.username}',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppTheme.spacingXS),
              Text(
                state.user.email,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}

class _WorkspaceSummary extends StatelessWidget {
  const _WorkspaceSummary({required this.workspace});

  final WorkspaceLoaded workspace;

  @override
  Widget build(BuildContext context) {
    final created = workspace.createdAt.toLocal();
    final updated = workspace.updatedAt?.toLocal();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.spacingL),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusL),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            workspace.name ?? 'Latest Workspace',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: AppTheme.spacingS),
          Text(
            'Created: ${created.toString().substring(0, 16)}'
            '${updated != null ? '\nUpdated: ${updated.toString().substring(0, 16)}' : ''}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: AppTheme.spacingM),
          Wrap(
            spacing: AppTheme.spacingM,
            runSpacing: AppTheme.spacingM,
            children: [
              _StatBadge(
                icon: Icons.library_books_outlined,
                label: 'Requirements',
                value: workspace.requirements.length.toString(),
                color: AppTheme.primaryColor,
              ),
              _StatBadge(
                icon: Icons.star_border,
                label: 'Prioritized',
                value: workspace.prioritizedRequirements.length.toString(),
                color: AppTheme.accentColor,
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingM),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    final requirements = workspace.requirements
                        .map((req) => req.copyWith())
                        .toList();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => RequirementsFormScreen(
                          initialRequirements: requirements,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.edit_note_outlined),
                  label: const Text('Continue Editing'),
                ),
              ),
              if (workspace.hasPrioritizedResults) ...[
                const SizedBox(width: AppTheme.spacingM),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ResultsScreen(
                            sessionId: workspace.sessionId,
                            prioritizedRequirements:
                                workspace.prioritizedRequirements,
                            metadata: null,
                            processingTimeMs: 0,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.leaderboard_outlined),
                    label: const Text('View Results'),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _StatBadge extends StatelessWidget {
  const _StatBadge({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingM,
        vertical: AppTheme.spacingS,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color),
          const SizedBox(width: AppTheme.spacingS),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w700,
                    ),
              ),
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _IntroSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
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
              size: 40,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: AppTheme.spacingM),
          Text(
            'ARIA',
            style: Theme.of(context).textTheme.displayLarge,
          ),
          const SizedBox(height: AppTheme.spacingXS),
          Text(
            'Advanced Requirements\nIntelligence & Analytics',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  height: 1.5,
                ),
          ),
        ],
      ),
    );
  }
}

class _FeaturesList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'AI-Powered Prioritization',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: AppTheme.spacingM),
        const _FeatureCard(
          icon: Icons.upload_file_outlined,
          title: 'Upload Requirements',
          description:
              'Import requirements from CSV or Excel files for instant analysis',
          color: AppTheme.primaryColor,
        ),
        const _FeatureCard(
          icon: Icons.edit_note_outlined,
          title: 'Manual Entry',
          description:
              'Create and manage requirements with our intuitive form interface',
          color: AppTheme.secondaryColor,
        ),
        const _FeatureCard(
          icon: Icons.analytics_outlined,
          title: 'Smart Analysis',
          description:
              'ML-powered multi-criteria analysis delivers objective prioritization',
          color: AppTheme.accentColor,
        ),
        const _FeatureCard(
          icon: Icons.download_outlined,
          title: 'Export Results',
          description:
              'Download prioritized requirements as CSV or HTML reports',
          color: AppTheme.warningColor,
        ),
      ],
    );
  }
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
  });

  final IconData icon;
  final String title;
  final String description;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingM),
      padding: const EdgeInsets.all(AppTheme.spacingL),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusL),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppTheme.radiusM),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: AppTheme.spacingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: AppTheme.spacingXS),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
