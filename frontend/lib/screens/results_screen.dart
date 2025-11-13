import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fl_chart/fl_chart.dart';
import '../theme/app_theme.dart';
import '../models/prioritized_requirement.dart';
import '../models/requirement.dart';
import '../models/api_response.dart';
import '../bloc/requirements_bloc.dart';
import '../bloc/requirements_event.dart';
import '../bloc/requirements_state.dart';
import '../widgets/dependency_graph.dart';
import '../utils/dependency_analyzer.dart';

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
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.prioritizedRequirements.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Prioritization Results'),
          elevation: 0,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.analytics_outlined,
                size: 64,
                color: AppTheme.textSecondary.withOpacity(0.5),
              ),
              const SizedBox(height: 16),
              Text(
                'No requirements to display',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Prioritization Results',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.textPrimary,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.download_outlined),
            onSelected: (value) {
              if (value == 'csv') {
                context.read<RequirementsBloc>().add(ExportCsvEvent(widget.sessionId));
              } else if (value == 'html') {
                context.read<RequirementsBloc>().add(ExportHtmlEvent(widget.sessionId));
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'csv',
                child: Row(
                  children: [
                    Icon(Icons.table_chart, color: AppTheme.primaryColor),
                    SizedBox(width: 12),
                    Text('Export as CSV'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'html',
                child: Row(
                  children: [
                    Icon(Icons.web, color: AppTheme.primaryColor),
                    SizedBox(width: 12),
                    Text('Export as HTML'),
                  ],
                ),
              ),
            ],
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 1,
                color: AppTheme.textTertiary.withOpacity(0.2),
              ),
              TabBar(
                controller: _tabController,
                isScrollable: false,
                indicatorColor: AppTheme.primaryColor,
                labelColor: AppTheme.primaryColor,
                unselectedLabelColor: AppTheme.textSecondary,
                indicatorWeight: 3,
                indicatorSize: TabBarIndicatorSize.tab,
                labelStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.normal,
                ),
                tabs: const [
                  Tab(
                    icon: Icon(Icons.list, size: 20),
                    text: 'List',
                  ),
                  Tab(
                    icon: Icon(Icons.bar_chart, size: 20),
                    text: 'Chart',
                  ),
                  Tab(
                    icon: Icon(Icons.account_tree, size: 20),
                    text: 'Dependencies',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      body: BlocListener<RequirementsBloc, RequirementsState>(
        listener: (context, state) {
          if (state is ExportSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.white),
                    const SizedBox(width: 12),
                    Text('Export successful: ${state.format.toUpperCase()}'),
                  ],
                ),
                backgroundColor: AppTheme.successColor,
                behavior: SnackBarBehavior.floating,
              ),
            );
          } else if (state is RequirementsError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.white),
                    const SizedBox(width: 12),
                    Expanded(child: Text(state.message)),
                  ],
                ),
                backgroundColor: AppTheme.errorColor,
                behavior: SnackBarBehavior.floating,
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
                physics: const BouncingScrollPhysics(),
                children: [
                  _buildRequirementsList(),
                  _buildChartView(),
                  _buildDependenciesView(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsBar() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryColor.withOpacity(0.1),
            AppTheme.secondaryColor.withOpacity(0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Row(
        children: [
          Expanded(
            child: _StatItem(
              icon: Icons.check_circle_outline,
              label: 'Requirements',
              value: '${widget.prioritizedRequirements.length}',
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _StatItem(
              icon: Icons.speed,
              label: 'Processing Time',
              value: '${widget.processingTimeMs}ms',
              color: AppTheme.accentColor,
            ),
          ),
          if (widget.metadata?.averageScore != null) ...[
            const SizedBox(width: 12),
            Expanded(
              child: _StatItem(
                icon: Icons.analytics_outlined,
                label: 'Avg Score',
                value: widget.metadata!.averageScore!.toStringAsFixed(1),
                color: AppTheme.secondaryColor,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRequirementsList() {
    final sortedRequirements =
        List<PrioritizedRequirement>.from(widget.prioritizedRequirements)
          ..sort((a, b) => a.rank.compareTo(b.rank));

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: sortedRequirements.length,
      itemBuilder: (context, index) {
        final requirement = sortedRequirements[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _RequirementCard(
            requirement: requirement,
            index: index,
          ),
        );
      },
    );
  }

  Widget _buildChartView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Priority Score Chart
          _buildPriorityScoreChart(),
          const SizedBox(height: 24),
          // Metrics Comparison Chart
          _buildMetricsChart(),
          const SizedBox(height: 24),
          // Category Distribution
          _buildCategoryChart(),
        ],
      ),
    );
  }

  Widget _buildPriorityScoreChart() {
    final sorted = List<PrioritizedRequirement>.from(widget.prioritizedRequirements)
      ..sort((a, b) => a.rank.compareTo(b.rank));
    
    final spots = sorted.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.priorityScore);
    }).toList();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Priority Scores by Rank',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 300,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: AppTheme.textTertiary.withOpacity(0.2),
                        strokeWidth: 1,
                      );
                    },
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() % 5 == 0 && value.toInt() < sorted.length) {
                            return Text(
                              '#${value.toInt() + 1}',
                              style: TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 12,
                              ),
                            );
                          }
                          return const Text('');
                        },
                        reservedSize: 30,
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            value.toInt().toString(),
                            style: TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 12,
                            ),
                          );
                        },
                        reservedSize: 40,
                      ),
                    ),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border.all(
                      color: AppTheme.textTertiary.withOpacity(0.3),
                    ),
                  ),
                  minX: 0,
                  maxX: (sorted.length - 1).toDouble(),
                  minY: 0,
                  maxY: 100,
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      color: AppTheme.primaryColor,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: AppTheme.primaryColor.withOpacity(0.1),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricsChart() {
    final sorted = List<PrioritizedRequirement>.from(widget.prioritizedRequirements)
      ..sort((a, b) => a.rank.compareTo(b.rank));
    
    // Группируем по топ-10 для читаемости
    final top10 = sorted.take(10).toList();
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Top 10 Requirements Metrics',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 300,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: 10,
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: AppTheme.textTertiary.withOpacity(0.2),
                        strokeWidth: 1,
                      );
                    },
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index < top10.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                '#${top10[index].rank}',
                                style: TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontSize: 10,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            );
                          }
                          return const Text('');
                        },
                        reservedSize: 40,
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            value.toInt().toString(),
                            style: TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 12,
                            ),
                          );
                        },
                        reservedSize: 40,
                      ),
                    ),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border.all(
                      color: AppTheme.textTertiary.withOpacity(0.3),
                    ),
                  ),
                  barGroups: top10.asMap().entries.map((entry) {
                    final req = entry.value;
                    return BarChartGroupData(
                      x: entry.key,
                      groupVertically: false,
                      barRods: [
                        BarChartRodData(
                          toY: req.businessValue ?? 0,
                          color: AppTheme.successColor,
                          width: 12,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(4),
                          ),
                        ),
                        BarChartRodData(
                          toY: req.cost ?? 0,
                          color: AppTheme.infoColor,
                          width: 12,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(4),
                          ),
                        ),
                        BarChartRodData(
                          toY: req.risk ?? 0,
                          color: AppTheme.errorColor,
                          width: 12,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(4),
                          ),
                        ),
                        BarChartRodData(
                          toY: req.urgency ?? 0,
                          color: AppTheme.warningColor,
                          width: 12,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(4),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                  groupsSpace: 20,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                _ChartLegendItem(color: AppTheme.successColor, label: 'Business Value'),
                _ChartLegendItem(color: AppTheme.infoColor, label: 'Cost'),
                _ChartLegendItem(color: AppTheme.errorColor, label: 'Risk'),
                _ChartLegendItem(color: AppTheme.warningColor, label: 'Urgency'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChart() {
    final categoryCounts = <RequirementCategory, int>{};
    for (var req in widget.prioritizedRequirements) {
      if (req.category != null) {
        categoryCounts[req.category!] = (categoryCounts[req.category] ?? 0) + 1;
      }
    }

    if (categoryCounts.isEmpty) {
      return Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: Text(
              'No category data available',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppTheme.textSecondary,
              ),
            ),
          ),
        ),
      );
    }

    final pieChartSections = categoryCounts.entries.map((entry) {
      final color = _getCategoryColor(entry.key);
      
      return PieChartSectionData(
        value: entry.value.toDouble(),
        title: '${entry.value}',
        color: color,
        radius: 80,
        titleStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Category Distribution',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 200,
                    child: PieChart(
                      PieChartData(
                        sections: pieChartSections,
                        sectionsSpace: 2,
                        centerSpaceRadius: 40,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: categoryCounts.entries.map((entry) {
                      final color = _getCategoryColor(entry.key);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Container(
                              width: 16,
                              height: 16,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _categoryToString(entry.key),
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ),
                            Text(
                              '${entry.value}',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDependenciesView() {
    // Анализируем зависимости
    final dependencies = DependencyAnalyzer.analyzeDependencies(
      widget.prioritizedRequirements,
    );

    return DependencyGraph(
      requirements: widget.prioritizedRequirements,
      dependencies: dependencies,
    );
  }

  Color _getCategoryColor(RequirementCategory category) {
    switch (category) {
      case RequirementCategory.feature:
        return AppTheme.primaryColor;
      case RequirementCategory.enhancement:
        return AppTheme.secondaryColor;
      case RequirementCategory.bugFix:
        return AppTheme.errorColor;
      case RequirementCategory.technical:
        return AppTheme.infoColor;
      case RequirementCategory.compliance:
        return AppTheme.successColor;
    }
  }

  String _categoryToString(RequirementCategory category) {
    switch (category) {
      case RequirementCategory.feature:
        return 'Feature';
      case RequirementCategory.enhancement:
        return 'Enhancement';
      case RequirementCategory.bugFix:
        return 'Bug Fix';
      case RequirementCategory.technical:
        return 'Technical';
      case RequirementCategory.compliance:
        return 'Compliance';
    }
  }
}

class _ChartLegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _ChartLegendItem({
    required this.color,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _RequirementCard extends StatelessWidget {
  final PrioritizedRequirement requirement;
  final int index;

  const _RequirementCard({
    required this.requirement,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final rankColor = _getRankColor();
    final scoreGradient = _getScoreGradient();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showDetailDialog(context),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: rankColor.withOpacity(0.3),
              width: requirement.rank <= 3 ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: rankColor.withOpacity(0.15),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with rank and score
                Row(
                  children: [
                    // Rank badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            rankColor,
                            rankColor.withOpacity(0.8),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: rankColor.withOpacity(0.4),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.flag, color: Colors.white, size: 16),
                          const SizedBox(width: 6),
                          Text(
                            '#${requirement.rank}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    // Priority score
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        gradient: scoreGradient,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryColor.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star, color: Colors.white, size: 18),
                          const SizedBox(width: 6),
                          Text(
                            requirement.priorityScore.toStringAsFixed(1),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Title
                Text(
                  requirement.title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                // Description
                Text(
                  requirement.description,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondary,
                    height: 1.5,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 16),
                // Metrics row
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (requirement.businessValue != null)
                      _MetricChip(
                        icon: Icons.trending_up,
                        label: 'Business',
                        value: requirement.businessValue!.toStringAsFixed(1),
                        color: AppTheme.successColor,
                      ),
                    if (requirement.urgency != null)
                      _MetricChip(
                        icon: Icons.schedule,
                        label: 'Urgency',
                        value: requirement.urgency!.toStringAsFixed(1),
                        color: AppTheme.warningColor,
                      ),
                    if (requirement.cost != null)
                      _MetricChip(
                        icon: Icons.attach_money,
                        label: 'Cost',
                        value: requirement.cost!.toStringAsFixed(1),
                        color: AppTheme.infoColor,
                      ),
                    if (requirement.risk != null)
                      _MetricChip(
                        icon: Icons.warning_amber_rounded,
                        label: 'Risk',
                        value: requirement.risk!.toStringAsFixed(1),
                        color: AppTheme.errorColor,
                      ),
                    if (requirement.category != null)
                      _CategoryChip(category: requirement.category!),
                  ],
                ),
                if (requirement.confidence != null) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(
                        Icons.verified,
                        size: 16,
                        color: AppTheme.successColor,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Confidence: ${(requirement.confidence! * 100).toStringAsFixed(0)}%',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getRankColor() {
    if (requirement.rank <= 3) return AppTheme.successColor;
    if (requirement.rank <= 10) return AppTheme.primaryColor;
    if (requirement.rank <= 20) return AppTheme.secondaryColor;
    return AppTheme.textSecondary;
  }

  LinearGradient _getScoreGradient() {
    final score = requirement.priorityScore;
    if (score >= 80) {
      return const LinearGradient(
        colors: [Color(0xFF34C759), Color(0xFF30D158)],
      );
    } else if (score >= 60) {
      return const LinearGradient(
        colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
      );
    } else {
      return LinearGradient(
        colors: [
          AppTheme.warningColor,
          AppTheme.warningColor.withOpacity(0.8),
        ],
      );
    }
  }

  String _categoryToString(RequirementCategory category) {
    switch (category) {
      case RequirementCategory.feature:
        return 'Feature';
      case RequirementCategory.enhancement:
        return 'Enhancement';
      case RequirementCategory.bugFix:
        return 'Bug Fix';
      case RequirementCategory.technical:
        return 'Technical';
      case RequirementCategory.compliance:
        return 'Compliance';
    }
  }

  Color _categoryColor(RequirementCategory category) {
    switch (category) {
      case RequirementCategory.feature:
        return AppTheme.primaryColor;
      case RequirementCategory.enhancement:
        return AppTheme.secondaryColor;
      case RequirementCategory.bugFix:
        return AppTheme.errorColor;
      case RequirementCategory.technical:
        return AppTheme.infoColor;
      case RequirementCategory.compliance:
        return AppTheme.successColor;
    }
  }

  void _showDetailDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: _getScoreGradient(),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '#${requirement.rank}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            requirement.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              // Content
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Description
                      Text(
                        requirement.description,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 24),
                      // Priority Score
                      _DetailMetricCard(
                        icon: Icons.star,
                        label: 'Priority Score',
                        value: requirement.priorityScore.toStringAsFixed(2),
                        color: AppTheme.primaryColor,
                      ),
                      const SizedBox(height: 12),
                      // Metrics Grid
                      Row(
                        children: [
                          if (requirement.businessValue != null)
                            Expanded(
                              child: _DetailMetricCard(
                                icon: Icons.trending_up,
                                label: 'Business Value',
                                value: requirement.businessValue!.toStringAsFixed(1),
                                color: AppTheme.successColor,
                              ),
                            ),
                          if (requirement.businessValue != null &&
                              requirement.cost != null)
                            const SizedBox(width: 12),
                          if (requirement.cost != null)
                            Expanded(
                              child: _DetailMetricCard(
                                icon: Icons.attach_money,
                                label: 'Cost',
                                value: requirement.cost!.toStringAsFixed(1),
                                color: AppTheme.infoColor,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          if (requirement.risk != null)
                            Expanded(
                              child: _DetailMetricCard(
                                icon: Icons.warning_amber_rounded,
                                label: 'Risk',
                                value: requirement.risk!.toStringAsFixed(1),
                                color: AppTheme.errorColor,
                              ),
                            ),
                          if (requirement.risk != null &&
                              requirement.urgency != null)
                            const SizedBox(width: 12),
                          if (requirement.urgency != null)
                            Expanded(
                              child: _DetailMetricCard(
                                icon: Icons.schedule,
                                label: 'Urgency',
                                value: requirement.urgency!.toStringAsFixed(1),
                                color: AppTheme.warningColor,
                              ),
                            ),
                        ],
                      ),
                      if (requirement.stakeholderValue != null) ...[
                        const SizedBox(height: 12),
                        _DetailMetricCard(
                          icon: Icons.people,
                          label: 'Stakeholder Value',
                          value: requirement.stakeholderValue!.toStringAsFixed(1),
                          color: AppTheme.secondaryColor,
                        ),
                      ],
                      if (requirement.confidence != null) ...[
                        const SizedBox(height: 12),
                        _DetailMetricCard(
                          icon: Icons.verified,
                          label: 'Confidence',
                          value: '${(requirement.confidence! * 100).toStringAsFixed(0)}%',
                          color: AppTheme.successColor,
                        ),
                      ],
                      if (requirement.category != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: _categoryColor(requirement.category!)
                                .withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.category,
                                color: _categoryColor(requirement.category!),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Category: ${_categoryToString(requirement.category!)}',
                                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: _categoryColor(requirement.category!),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      if (requirement.reasoning != null) ...[
                        const SizedBox(height: 24),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppTheme.backgroundColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppTheme.textTertiary.withOpacity(0.3),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.lightbulb_outline,
                                    color: AppTheme.warningColor,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'AI Reasoning',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                requirement.reasoning!,
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _MetricChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            '$label: $value',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final RequirementCategory category;

  const _CategoryChip({required this.category});

  Color _getColor() {
    switch (category) {
      case RequirementCategory.feature:
        return AppTheme.primaryColor;
      case RequirementCategory.enhancement:
        return AppTheme.secondaryColor;
      case RequirementCategory.bugFix:
        return AppTheme.errorColor;
      case RequirementCategory.technical:
        return AppTheme.infoColor;
      case RequirementCategory.compliance:
        return AppTheme.successColor;
    }
  }

  String _getLabel() {
    switch (category) {
      case RequirementCategory.feature:
        return 'Feature';
      case RequirementCategory.enhancement:
        return 'Enhancement';
      case RequirementCategory.bugFix:
        return 'Bug Fix';
      case RequirementCategory.technical:
        return 'Technical';
      case RequirementCategory.compliance:
        return 'Compliance';
    }
  }

  IconData _getIcon() {
    switch (category) {
      case RequirementCategory.feature:
        return Icons.extension;
      case RequirementCategory.enhancement:
        return Icons.upgrade;
      case RequirementCategory.bugFix:
        return Icons.bug_report;
      case RequirementCategory.technical:
        return Icons.build;
      case RequirementCategory.compliance:
        return Icons.verified_user;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getColor();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withOpacity(0.8)],
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.category, size: 16, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            _getLabel(),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailMetricCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _DetailMetricCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
