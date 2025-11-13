import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../theme/app_theme.dart';
import '../models/prioritized_requirement.dart';
import '../utils/dependency_analyzer.dart';

/// Виджет для визуализации графа зависимостей требований
class DependencyGraph extends StatefulWidget {
  final List<PrioritizedRequirement> requirements;
  final List<RequirementDependency> dependencies;

  const DependencyGraph({
    super.key,
    required this.requirements,
    required this.dependencies,
  });

  @override
  State<DependencyGraph> createState() => _DependencyGraphState();
}

class _DependencyGraphState extends State<DependencyGraph> {
  final TransformationController _transformationController =
      TransformationController();
  final Map<String, Offset> _nodePositions = {};
  final Map<String, PrioritizedRequirement> _requirementMap = {};
  String? _selectedNodeId;

  @override
  void initState() {
    super.initState();
    _initializeNodes();
  }

  @override
  void didUpdateWidget(DependencyGraph oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.requirements != widget.requirements ||
        oldWidget.dependencies != widget.dependencies) {
      _initializeNodes();
    }
  }

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  void _initializeNodes() {
    _requirementMap.clear();
    _requirementMap.addAll({
      for (var req in widget.requirements) req.id: req,
    });

    _layoutNodes();
  }

  void _layoutNodes() {
    final count = widget.requirements.length;
    if (count == 0) return;

    // Сортируем по рангу
    final sorted = List<PrioritizedRequirement>.from(widget.requirements)
      ..sort((a, b) => a.rank.compareTo(b.rank));

    // Располагаем узлы в виде круга
    final centerX = 500.0;
    final centerY = 400.0;
    final radius = math.min(280.0, count * 40.0);

    _nodePositions.clear();
    for (var i = 0; i < count; i++) {
      final req = sorted[i];
      final angle = (2 * math.pi * i) / count - math.pi / 2;
      _nodePositions[req.id] = Offset(
        centerX + radius * math.cos(angle),
        centerY + radius * math.sin(angle),
      );
    }
  }

  void _resetView() {
    _transformationController.value = Matrix4.identity();
    setState(() {
      _selectedNodeId = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.requirements.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.account_tree,
              size: 64,
              color: AppTheme.textSecondary.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No requirements to visualize',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return Stack(
      children: [
        // Граф с интерактивным просмотром
        InteractiveViewer(
          transformationController: _transformationController,
          minScale: 0.3,
          maxScale: 2.5,
          boundaryMargin: const EdgeInsets.all(200),
          child: SizedBox(
            width: 1000,
            height: 800,
            child: Stack(
              children: [
                // Рисуем связи
                CustomPaint(
                  size: const Size(1000, 800),
                  painter: _DependencyEdgesPainter(
                    dependencies: widget.dependencies,
                    nodePositions: _nodePositions,
                  ),
                ),
                // Рисуем узлы
                ..._buildNodeWidgets(),
              ],
            ),
          ),
        ),
        // Панель управления
        Positioned(
          top: 16,
          right: 16,
          child: _ControlPanel(
            onReset: _resetView,
            dependenciesCount: widget.dependencies.length,
          ),
        ),
        // Легенда
        Positioned(
          bottom: 16,
          left: 16,
          child: _LegendWidget(dependencies: widget.dependencies),
        ),
        // Информация о выбранном узле
        if (_selectedNodeId != null &&
            _requirementMap.containsKey(_selectedNodeId))
          Positioned(
            top: 16,
            left: 16,
            child: _NodeInfoCard(
              requirement: _requirementMap[_selectedNodeId]!,
              dependencies: widget.dependencies
                  .where((d) =>
                      d.fromId == _selectedNodeId || d.toId == _selectedNodeId)
                  .toList(),
              allRequirements: widget.requirements,
              onClose: () {
                setState(() {
                  _selectedNodeId = null;
                });
              },
            ),
          ),
      ],
    );
  }

  List<Widget> _buildNodeWidgets() {
    return _nodePositions.entries.map((entry) {
      final req = _requirementMap[entry.key];
      if (req == null) return const SizedBox.shrink();

      final isSelected = _selectedNodeId == entry.key;
      final rankColor = _getRankColor(req.rank);

      return Positioned(
        left: entry.value.dx - 50,
        top: entry.value.dy - 50,
        child: GestureDetector(
          onTap: () {
            setState(() {
              _selectedNodeId = _selectedNodeId == entry.key ? null : entry.key;
            });
          },
          child: Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.transparent,
            ),
            child: Center(
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      rankColor.withOpacity(0.3),
                      rankColor.withOpacity(0.1),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? rankColor : rankColor.withOpacity(0.8),
                    width: isSelected ? 4.0 : 2.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: rankColor.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '#${req.rank}',
                      style: TextStyle(
                        color: rankColor,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Text(
                        req.title.length > 12
                            ? '${req.title.substring(0, 12)}...'
                            : req.title,
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }).toList();
  }

  Color _getRankColor(int rank) {
    if (rank <= 3) return AppTheme.successColor;
    if (rank <= 10) return AppTheme.primaryColor;
    if (rank <= 20) return AppTheme.secondaryColor;
    return AppTheme.textSecondary;
  }
}

/// CustomPainter для рисования связей (стрелок) между узлами
class _DependencyEdgesPainter extends CustomPainter {
  final List<RequirementDependency> dependencies;
  final Map<String, Offset> nodePositions;

  _DependencyEdgesPainter({
    required this.dependencies,
    required this.nodePositions,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (var dep in dependencies) {
      final fromPos = nodePositions[dep.fromId];
      final toPos = nodePositions[dep.toId];

      if (fromPos == null || toPos == null) continue;

      // Выбираем цвет в зависимости от типа зависимости
      Color edgeColor;
      switch (dep.type) {
        case DependencyType.dependsOn:
          edgeColor = AppTheme.primaryColor;
          break;
        case DependencyType.blocks:
          edgeColor = AppTheme.errorColor;
          break;
        case DependencyType.related:
          edgeColor = AppTheme.secondaryColor;
          break;
      }

      final edgePaint = Paint()
        ..color = edgeColor.withOpacity(0.6)
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke;

      _drawArrow(canvas, fromPos, toPos, edgePaint);
    }
  }

  void _drawArrow(Canvas canvas, Offset from, Offset to, Paint paint) {
    final angle = math.atan2(to.dy - from.dy, to.dx - from.dx);
    final arrowLength = 12.0;
    final arrowAngle = math.pi / 6;
    final nodeRadius = 40.0;
    final distance = (to - from).distance;

    if (distance < nodeRadius * 2) return;

    final dx = (to.dx - from.dx) * (1 - nodeRadius / distance);
    final dy = (to.dy - from.dy) * (1 - nodeRadius / distance);
    final adjustedTo = Offset(from.dx + dx, from.dy + dy);
    final adjustedFrom = Offset(
      from.dx + (to.dx - from.dx) * (nodeRadius / distance),
      from.dy + (to.dy - from.dy) * (nodeRadius / distance),
    );

    // Рисуем линию
    final path = Path();
    path.moveTo(adjustedFrom.dx, adjustedFrom.dy);
    path.lineTo(adjustedTo.dx, adjustedTo.dy);
    canvas.drawPath(path, paint);

    // Рисуем наконечник стрелки
    final arrowPath = Path();
    arrowPath.moveTo(adjustedTo.dx, adjustedTo.dy);
    arrowPath.lineTo(
      adjustedTo.dx - arrowLength * math.cos(angle - arrowAngle),
      adjustedTo.dy - arrowLength * math.sin(angle - arrowAngle),
    );
    arrowPath.lineTo(
      adjustedTo.dx - arrowLength * math.cos(angle + arrowAngle),
      adjustedTo.dy - arrowLength * math.sin(angle + arrowAngle),
    );
    arrowPath.close();

    final fillPaint = Paint()
      ..color = paint.color
      ..style = PaintingStyle.fill;
    canvas.drawPath(arrowPath, fillPaint);
  }

  @override
  bool shouldRepaint(_DependencyEdgesPainter oldDelegate) {
    return oldDelegate.dependencies != dependencies ||
        oldDelegate.nodePositions != nodePositions;
  }
}

class _ControlPanel extends StatelessWidget {
  final VoidCallback onReset;
  final int dependenciesCount;

  const _ControlPanel({
    required this.onReset,
    required this.dependenciesCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppTheme.primaryColor),
            onPressed: onReset,
            tooltip: 'Reset View',
          ),
          const Divider(),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Text(
                  '$dependenciesCount',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Dependencies',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendWidget extends StatelessWidget {
  final List<RequirementDependency> dependencies;

  const _LegendWidget({required this.dependencies});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline,
                  size: 18, color: AppTheme.primaryColor),
              const SizedBox(width: 8),
              Text(
                'Legend',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _LegendItem(
            color: AppTheme.primaryColor,
            label: 'Depends On',
          ),
          const SizedBox(height: 8),
          _LegendItem(
            color: AppTheme.errorColor,
            label: 'Blocks',
          ),
          const SizedBox(height: 8),
          _LegendItem(
            color: AppTheme.secondaryColor,
            label: 'Related',
          ),
          if (dependencies.isEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.backgroundColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'No dependencies found.\nDependencies are detected from requirement descriptions.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({
    required this.color,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 24,
          height: 3,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _NodeInfoCard extends StatelessWidget {
  final PrioritizedRequirement requirement;
  final List<RequirementDependency> dependencies;
  final List<PrioritizedRequirement> allRequirements;
  final VoidCallback onClose;

  const _NodeInfoCard({
    required this.requirement,
    required this.dependencies,
    required this.allRequirements,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final rankColor = _getRankColor(requirement.rank);

    return Container(
      constraints: const BoxConstraints(maxWidth: 320),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: AppTheme.cardShadow,
        border: Border.all(color: rankColor, width: 2),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [rankColor, rankColor.withOpacity(0.8)],
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '#${requirement.rank}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      requirement.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 20),
                onPressed: onClose,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            requirement.description,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppTheme.textSecondary,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          if (dependencies.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Divider(),
            Text(
              'Dependencies',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ...dependencies.map((dep) {
              final relatedReq = allRequirements.firstWhere(
                (r) => r.id == (dep.fromId == requirement.id ? dep.toId : dep.fromId),
              );
              final isOutgoing = dep.fromId == requirement.id;
              final depColor = _getDependencyColor(dep.type);
              
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Icon(
                      isOutgoing ? Icons.arrow_forward : Icons.arrow_back,
                      size: 16,
                      color: depColor,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isOutgoing ? 'Depends on' : 'Required by',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.textSecondary,
                              fontSize: 11,
                            ),
                          ),
                          Text(
                            relatedReq.title,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  Color _getRankColor(int rank) {
    if (rank <= 3) return AppTheme.successColor;
    if (rank <= 10) return AppTheme.primaryColor;
    if (rank <= 20) return AppTheme.secondaryColor;
    return AppTheme.textSecondary;
  }

  Color _getDependencyColor(DependencyType type) {
    switch (type) {
      case DependencyType.dependsOn:
        return AppTheme.primaryColor;
      case DependencyType.blocks:
        return AppTheme.errorColor;
      case DependencyType.related:
        return AppTheme.secondaryColor;
    }
  }
}
