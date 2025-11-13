import '../models/prioritized_requirement.dart';

/// Модель зависимости между требованиями
class RequirementDependency {
  final String fromId;
  final String toId;
  final DependencyType type;
  final String? reason;

  const RequirementDependency({
    required this.fromId,
    required this.toId,
    required this.type,
    this.reason,
  });
}

/// Тип зависимости
enum DependencyType {
  dependsOn, // Требование A зависит от требования B
  blocks, // Требование A блокирует требование B
  related, // Требования связаны, но тип связи не определен
}

/// Анализатор зависимостей между требованиями
class DependencyAnalyzer {
  /// Анализирует требования и извлекает зависимости из описаний
  static List<RequirementDependency> analyzeDependencies(
    List<PrioritizedRequirement> requirements,
  ) {
    final dependencies = <RequirementDependency>[];
    final requirementMap = {
      for (var req in requirements) req.id: req,
    };

    for (var req in requirements) {
      final description = req.description.toLowerCase();
      final title = req.title.toLowerCase();

      // Ищем упоминания ID других требований
      for (var otherReq in requirements) {
        if (otherReq.id == req.id) continue;

        // Поиск по ID в разных форматах
        final idPatterns = [
          otherReq.id.toLowerCase(),
          otherReq.id.replaceAll('-', ' ').toLowerCase(),
          'req-${otherReq.id.split('-').last}',
          'requirement ${otherReq.id.split('-').last}',
        ];

        for (var pattern in idPatterns) {
          if (description.contains(pattern) || title.contains(pattern)) {
            // Определяем тип зависимости по контексту
            DependencyType? type = _detectDependencyType(
              description,
              title,
              pattern,
            );

            if (type != null) {
              dependencies.add(
                RequirementDependency(
                  fromId: req.id,
                  toId: otherReq.id,
                  type: type,
                  reason: _extractReason(description, pattern),
                ),
              );
              break; // Найдена зависимость, переходим к следующему требованию
            }
          }
        }

        // Поиск зависимостей по ключевым словам и семантической близости
        final semanticDependency = _detectSemanticDependency(
          req,
          otherReq,
          requirementMap.values.toList(),
        );
        if (semanticDependency != null) {
          // Проверяем, не добавили ли мы уже эту зависимость
          final exists = dependencies.any(
            (d) => d.fromId == req.id && d.toId == otherReq.id,
          );
          if (!exists) {
            dependencies.add(semanticDependency);
          }
        }
      }
    }

    return dependencies;
  }

  /// Определяет тип зависимости по контексту
  static DependencyType? _detectDependencyType(
    String description,
    String title,
    String pattern,
  ) {
    final dependsKeywords = [
      'depends on',
      'requires',
      'needs',
      'after',
      'following',
      'based on',
      'builds on',
      'extends',
    ];

    final blocksKeywords = [
      'blocks',
      'prevents',
      'must be before',
      'prerequisite',
    ];

    final relatedKeywords = [
      'related to',
      'connected to',
      'similar to',
      'part of',
    ];

    // Ищем ключевые слова перед упоминанием ID
    final patternIndex = description.indexOf(pattern);
    if (patternIndex == -1) return null;

    final beforePattern = description.substring(
      (patternIndex - 50).clamp(0, patternIndex),
      patternIndex,
    ).toLowerCase();

    for (var keyword in dependsKeywords) {
      if (beforePattern.contains(keyword)) {
        return DependencyType.dependsOn;
      }
    }

    for (var keyword in blocksKeywords) {
      if (beforePattern.contains(keyword)) {
        return DependencyType.blocks;
      }
    }

    for (var keyword in relatedKeywords) {
      if (beforePattern.contains(keyword)) {
        return DependencyType.related;
      }
    }

    // Если найдено упоминание, но тип не определен, используем dependsOn по умолчанию
    return DependencyType.dependsOn;
  }

  /// Извлекает причину зависимости из текста
  static String? _extractReason(String description, String pattern) {
    final patternIndex = description.indexOf(pattern);
    if (patternIndex == -1) return null;

    final start = (patternIndex - 30).clamp(0, patternIndex);
    final end = (patternIndex + pattern.length + 30).clamp(
      patternIndex + pattern.length,
      description.length,
    );

    return description.substring(start, end).trim();
  }

  /// Обнаруживает семантические зависимости на основе содержания
  static RequirementDependency? _detectSemanticDependency(
    PrioritizedRequirement fromReq,
    PrioritizedRequirement toReq,
    List<PrioritizedRequirement> allRequirements,
  ) {
    // Простая эвристика: если требования имеют похожие категории и
    // одно имеет более высокий приоритет, может быть зависимость
    if (fromReq.category == toReq.category &&
        fromReq.category != null &&
        fromReq.rank < toReq.rank) {
      // Требование с более высоким приоритетом может зависеть от требования с более низким
      // Это просто пример, можно улучшить логику
      return RequirementDependency(
        fromId: fromReq.id,
        toId: toReq.id,
        type: DependencyType.related,
        reason: 'Same category, related requirements',
      );
    }

    // Проверка на общие ключевые слова в описаниях
    final fromWords = _extractKeywords(fromReq.description);
    final toWords = _extractKeywords(toReq.description);
    final commonWords = fromWords.intersection(toWords);

    // Если есть значительное пересечение ключевых слов
    if (commonWords.length >= 3) {
      return RequirementDependency(
        fromId: fromReq.id,
        toId: toReq.id,
        type: DependencyType.related,
        reason: 'Shared keywords: ${commonWords.take(3).join(", ")}',
      );
    }

    return null;
  }

  /// Извлекает ключевые слова из текста
  static Set<String> _extractKeywords(String text) {
    final words = text
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), ' ')
        .split(' ')
        .where((word) => word.length > 4)
        .where((word) => !_isStopWord(word))
        .toSet();
    return words;
  }

  /// Проверяет, является ли слово стоп-словом
  static bool _isStopWord(String word) {
    const stopWords = {
      'this',
      'that',
      'these',
      'those',
      'which',
      'where',
      'when',
      'what',
      'will',
      'would',
      'could',
      'should',
      'must',
      'might',
      'may',
      'can',
      'have',
      'has',
      'had',
      'been',
      'being',
      'were',
      'was',
      'are',
      'is',
      'am',
      'the',
      'and',
      'or',
      'but',
      'with',
      'from',
      'into',
      'onto',
      'upon',
      'over',
      'under',
      'above',
      'below',
      'between',
      'among',
      'during',
      'before',
      'after',
      'through',
      'within',
      'without',
    };
    return stopWords.contains(word);
  }
}

