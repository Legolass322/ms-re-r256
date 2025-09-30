import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../theme/app_theme.dart';
import '../models/prioritized_requirement.dart';
import '../models/api_response.dart';
import '../bloc/requirements_bloc.dart';
import '../bloc/requirements_event.dart';
import '../bloc/requirements_state.dart';

class ResultsScreen extends StatefulWidget {
  final String sessionId;
  final List<PrioritizedRequirement> prioritizedRequirements;
  final PrioritizationMetadata? metadata;
  final int processingTimeMs;

  const ResultsScreen({
    super.key,
    required this.sessionId,
    required this.prioritizedRequirements,
    this.metadata,
    required this.processingTimeMs,
  });

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _exportCsv() async {
    context.read<RequirementsBloc>().add(ExportCsvEvent(widget.sessionId));
  }

  Future<void> _exportHtml() async {
    context.read<RequirementsBloc>().add(ExportHtmlEvent(widget.sessionId));
  }

  Future<void> _saveExportedData(String data, String filename) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$filename');
      await file.writeAsString(data);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Exported to ${file.path}'),
            backgroundColor: AppTheme.successColor,
            action: SnackBarAction(
              label: 'OK',
              textColor: Colors.white,
              onPressed: () {},
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving file: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Prioritization Results'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.download_outlined),
            onSelected: (value) {
              if (value == 'csv') {
                _exportCsv();
              } else if (value == 'html') {
                _exportHtml();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'csv',
                child: Row(
                  children: [
                    Icon(Icons.table_chart),
                    SizedBox(width: AppTheme.spacingS),
                    Text('Export as CSV'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'html',
                child: Row(
                  children: [
                    Icon(Icons.web),
                    SizedBox(width: AppTheme.spacingS),
                    Text('Export as HTML'),
                  ],
                ),
              ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'List View'),
            Tab(text: 'Chart View'),
          ],
        ),
      ),
      body: BlocListener<RequirementsBloc, RequirementsState>(
        listener: (context, state) {
          if (state is ExportSuccess) {
            final filename = state.format == 'csv'
                ? 'aria_export_${DateTime.now().millisecondsSinceEpoch}.csv'
                : 'aria_export_${DateTime.now().millisecondsSinceEpoch}.html';
            _saveExportedData(state.data, filename);
          } else if (state is RequirementsError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppTheme.errorColor,
              ),
            );
          }
        },
        child: Column(
          children: [
            _buildStatsBar(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [_buildListView(), _buildChartView()],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsBar() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingM),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          _StatChip(
            icon: Icons.check_circle_outline,
            label: 'Requirements',
            value: '${widget.prioritizedRequirements.length}',
            color: AppTheme.primaryColor,
          ),
          const SizedBox(width: AppTheme.spacingM),
          _StatChip(
            icon: Icons.speed,
            label: 'Processing Time',
            value: '${widget.processingTimeMs}ms',
            color: AppTheme.accentColor,
          ),
          if (widget.metadata?.averageScore != null) ...[
            const SizedBox(width: AppTheme.spacingM),
            _StatChip(
              icon: Icons.analytics_outlined,
              label: 'Avg Score',
              value: widget.metadata!.averageScore!.toStringAsFixed(1),
              color: AppTheme.secondaryColor,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildListView() {
    return ListView.builder(
      padding: const EdgeInsets.all(AppTheme.spacingM),
      itemCount: widget.prioritizedRequirements.length,
      itemBuilder: (context, index) {
        final requirement = widget.prioritizedRequirements[index];
        return _PrioritizedRequirementCard(
          requirement: requirement,
          index: index,
        );
      },
    );
  }

  Widget _buildChartView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spacingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Priority Score Distribution',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: AppTheme.spacingL),

          // Bar Chart
          SizedBox(height: 300, child: _buildBarChart()),

          const SizedBox(height: AppTheme.spacingXXL),

          Text(
            'Top 10 Requirements',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: AppTheme.spacingL),

          // Top 10 horizontal bar chart
          SizedBox(height: 400, child: _buildHorizontalBarChart()),
        ],
      ),
    );
  }

  Widget _buildBarChart() {
    final top20 = widget.prioritizedRequirements.take(20).toList();

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: 100,
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              return BarTooltipItem(
                '${top20[group.x.toInt()].title}\n',
                const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
                children: [
                  TextSpan(
                    text: rod.toY.toStringAsFixed(1),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= top20.length) return const Text('');
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    '${value.toInt() + 1}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toInt().toString(),
                  style: Theme.of(context).textTheme.bodySmall,
                );
              },
            ),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 20,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: AppTheme.textTertiary.withOpacity(0.2),
              strokeWidth: 1,
            );
          },
        ),
        borderData: FlBorderData(show: false),
        barGroups: List.generate(
          top20.length,
          (index) => BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: top20[index].priorityScore,
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primaryColor.withOpacity(0.8),
                    AppTheme.secondaryColor.withOpacity(0.8),
                  ],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
                width: 16,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(4),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHorizontalBarChart() {
    final top10 = widget.prioritizedRequirements.take(10).toList();

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: 100,
        barTouchData: BarTouchData(enabled: false),
        titlesData: FlTitlesData(
          show: true,
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 150,
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= top10.length) return const Text('');
                final req = top10[value.toInt()];
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Text(
                    req.title.length > 20
                        ? '${req.title.substring(0, 20)}...'
                        : req.title,
                    style: Theme.of(context).textTheme.bodySmall,
                    textAlign: TextAlign.right,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toInt().toString(),
                  style: Theme.of(context).textTheme.bodySmall,
                );
              },
            ),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        gridData: FlGridData(
          show: true,
          drawHorizontalLine: false,
          verticalInterval: 20,
          getDrawingVerticalLine: (value) {
            return FlLine(
              color: AppTheme.textTertiary.withOpacity(0.2),
              strokeWidth: 1,
            );
          },
        ),
        borderData: FlBorderData(show: false),
        barGroups: List.generate(
          top10.length,
          (index) => BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: top10[index].priorityScore,
                gradient: LinearGradient(
                  colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
                ),
                width: 24,
                borderRadius: const BorderRadius.horizontal(
                  right: Radius.circular(4),
                ),
              ),
            ],
          ),
        ),
      ),
      swapAnimationDuration: const Duration(milliseconds: 300),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(AppTheme.spacingS),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppTheme.radiusM),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: AppTheme.spacingXS),
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
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _PrioritizedRequirementCard extends StatelessWidget {
  final PrioritizedRequirement requirement;
  final int index;

  const _PrioritizedRequirementCard({
    required this.requirement,
    required this.index,
  });

  Color get _rankColor {
    if (requirement.rank <= 3) return AppTheme.successColor;
    if (requirement.rank <= 10) return AppTheme.primaryColor;
    if (requirement.rank <= 20) return AppTheme.secondaryColor;
    return AppTheme.textSecondary;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingM),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusL),
        boxShadow: AppTheme.cardShadow,
        border: requirement.rank <= 3
            ? Border.all(
                color: AppTheme.successColor.withOpacity(0.3),
                width: 2,
              )
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (context) =>
                  _RequirementDetailSheet(requirement: requirement),
            );
          },
          borderRadius: BorderRadius.circular(AppTheme.radiusL),
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.spacingM),
            child: Row(
              children: [
                // Rank Badge
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: _rankColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppTheme.radiusM),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '#${requirement.rank}',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: _rankColor,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: AppTheme.spacingM),

                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        requirement.title,
                        style: Theme.of(context).textTheme.titleMedium,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: AppTheme.spacingXS),
                      Text(
                        requirement.description,
                        style: Theme.of(context).textTheme.bodyMedium,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: AppTheme.spacingM),

                // Score
                Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.spacingM,
                        vertical: AppTheme.spacingS,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppTheme.primaryColor,
                            AppTheme.secondaryColor,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(AppTheme.radiusM),
                      ),
                      child: Text(
                        requirement.priorityScore.toStringAsFixed(1),
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ),
                    if (requirement.confidence != null) ...[
                      const SizedBox(height: AppTheme.spacingXS),
                      Text(
                        '${(requirement.confidence! * 100).toStringAsFixed(0)}%',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
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

class _RequirementDetailSheet extends StatelessWidget {
  final PrioritizedRequirement requirement;

  const _RequirementDetailSheet({required this.requirement});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppTheme.radiusL),
        ),
      ),
      padding: const EdgeInsets.all(AppTheme.spacingL),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.spacingM,
                      vertical: AppTheme.spacingS,
                    ),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          AppTheme.primaryColor,
                          AppTheme.secondaryColor,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(AppTheme.radiusM),
                    ),
                    child: Text(
                      'Priority Rank #${requirement.rank}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.spacingL),

              Text(
                requirement.title,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: AppTheme.spacingM),

              Text(
                requirement.description,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: AppTheme.spacingL),

              _DetailRow(
                label: 'Priority Score',
                value: requirement.priorityScore.toStringAsFixed(2),
              ),
              if (requirement.confidence != null)
                _DetailRow(
                  label: 'Confidence',
                  value:
                      '${(requirement.confidence! * 100).toStringAsFixed(0)}%',
                ),
              if (requirement.businessValue != null)
                _DetailRow(
                  label: 'Business Value',
                  value: requirement.businessValue!.toStringAsFixed(1),
                ),
              if (requirement.cost != null)
                _DetailRow(
                  label: 'Cost',
                  value: requirement.cost!.toStringAsFixed(1),
                ),
              if (requirement.risk != null)
                _DetailRow(
                  label: 'Risk',
                  value: requirement.risk!.toStringAsFixed(1),
                ),
              if (requirement.urgency != null)
                _DetailRow(
                  label: 'Urgency',
                  value: requirement.urgency!.toStringAsFixed(1),
                ),
              if (requirement.stakeholderValue != null)
                _DetailRow(
                  label: 'Stakeholder Value',
                  value: requirement.stakeholderValue!.toStringAsFixed(1),
                ),

              if (requirement.reasoning != null) ...[
                const SizedBox(height: AppTheme.spacingL),
                Text(
                  'AI Reasoning',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: AppTheme.spacingS),
                Container(
                  padding: const EdgeInsets.all(AppTheme.spacingM),
                  decoration: BoxDecoration(
                    color: AppTheme.backgroundColor,
                    borderRadius: BorderRadius.circular(AppTheme.radiusM),
                  ),
                  child: Text(
                    requirement.reasoning!,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spacingS),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          Text(value, style: Theme.of(context).textTheme.titleMedium),
        ],
      ),
    );
  }
}
