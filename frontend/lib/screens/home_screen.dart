import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'upload_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.spacingL),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: AppTheme.spacingXXL),

                // Logo/Header
                Center(
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
                        style: Theme.of(
                          context,
                        ).textTheme.bodyMedium?.copyWith(height: 1.5),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppTheme.spacingXXL),

                // Features
                Text(
                  'AI-Powered Prioritization',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: AppTheme.spacingM),

                _FeatureCard(
                  icon: Icons.upload_file_outlined,
                  title: 'Upload Requirements',
                  description:
                      'Import requirements from CSV or Excel files for instant analysis',
                  color: AppTheme.primaryColor,
                ),

                _FeatureCard(
                  icon: Icons.edit_note_outlined,
                  title: 'Manual Entry',
                  description:
                      'Create and manage requirements with our intuitive form interface',
                  color: AppTheme.secondaryColor,
                ),

                _FeatureCard(
                  icon: Icons.analytics_outlined,
                  title: 'Smart Analysis',
                  description:
                      'ML-powered multi-criteria analysis delivers objective prioritization',
                  color: AppTheme.accentColor,
                ),

                _FeatureCard(
                  icon: Icons.download_outlined,
                  title: 'Export Results',
                  description:
                      'Download prioritized requirements as CSV or HTML reports',
                  color: AppTheme.warningColor,
                ),

                const SizedBox(height: AppTheme.spacingXL),

                // CTA Button
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
                    child: const Text('Get Started'),
                  ),
                ),

                const SizedBox(height: AppTheme.spacingM),

                // Info text
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
          ),
        ),
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Color color;

  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
  });

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
