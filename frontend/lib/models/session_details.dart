import 'package:equatable/equatable.dart';

import 'requirement.dart';
import 'prioritized_requirement.dart';
import 'requirement.dart' show RequirementCategory;

class SessionDetails extends Equatable {
  final String sessionId;
  final String? name;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final List<Requirement> requirements;
  final List<PrioritizedRequirement> prioritizedRequirements;

  const SessionDetails({
    required this.sessionId,
    this.name,
    required this.createdAt,
    this.updatedAt,
    required this.requirements,
    required this.prioritizedRequirements,
  });

  factory SessionDetails.fromJson(Map<String, dynamic> json) {
    final requirementsJson = json['requirements'] as List<dynamic>? ?? [];
    final prioritizedJson =
        json['prioritizedRequirements'] as List<dynamic>? ?? [];

    // Manually parse prioritized requirements to avoid type errors
    final List<PrioritizedRequirement> prioritizedRequirements = [];
    for (var i = 0; i < prioritizedJson.length; i++) {
      final reqData = prioritizedJson[i];
      if (reqData is! Map<String, dynamic>) continue;
      
      try {
        // Helper to parse doubles safely
        double? parseDouble(dynamic value) {
          if (value == null) return null;
          if (value is double) return value;
          if (value is int) return value.toDouble();
          if (value is num) return value.toDouble();
          return double.tryParse(value.toString());
        }
        
        int? parseInt(dynamic value) {
          if (value == null) return null;
          if (value is int) return value;
          if (value is double) return value.toInt();
          if (value is num) return value.toInt();
          return int.tryParse(value.toString());
        }
        
        final id = reqData['id']?.toString() ?? '';
        final title = reqData['title']?.toString() ?? '';
        final description = reqData['description']?.toString() ?? '';
        final businessValue = parseDouble(reqData['businessValue']);
        final cost = parseDouble(reqData['cost']);
        final risk = parseDouble(reqData['risk']);
        final urgency = parseDouble(reqData['urgency']);
        final stakeholderValue = parseDouble(reqData['stakeholderValue']);
        final categoryStr = reqData['category']?.toString();
        final priorityScore = parseDouble(reqData['priorityScore']) ?? 0.0;
        final rank = parseInt(reqData['rank']) ?? 0;
        final confidence = parseDouble(reqData['confidence']);
        final reasoning = reqData['reasoning']?.toString();
        
        // Parse category enum - handle various string formats
        RequirementCategory? category;
        if (categoryStr != null && categoryStr.isNotEmpty) {
          try {
            final normalized = categoryStr.toUpperCase().replaceAll('_', '');
            category = RequirementCategory.values.firstWhere(
              (e) {
                final enumName = e.toString().split('.').last.toUpperCase();
                return enumName == normalized ||
                    (normalized == 'FEATURE' && e == RequirementCategory.feature) ||
                    (normalized == 'ENHANCEMENT' && e == RequirementCategory.enhancement) ||
                    (normalized == 'BUGFIX' && e == RequirementCategory.bugFix) ||
                    (normalized == 'TECHNICAL' && e == RequirementCategory.technical) ||
                    (normalized == 'COMPLIANCE' && e == RequirementCategory.compliance);
              },
              orElse: () => RequirementCategory.feature,
            );
          } catch (e) {
            category = null;
          }
        }
        
        prioritizedRequirements.add(PrioritizedRequirement(
          id: id,
          title: title,
          description: description,
          businessValue: businessValue,
          cost: cost,
          risk: risk,
          urgency: urgency,
          stakeholderValue: stakeholderValue,
          category: category,
          priorityScore: priorityScore,
          rank: rank,
          confidence: confidence,
          reasoning: reasoning,
        ));
      } catch (e) {
        // Skip invalid requirements
        continue;
      }
    }

    return SessionDetails(
      sessionId: json['sessionId'] as String,
      name: json['name'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'] as String)
          : null,
      requirements: requirementsJson
          .map((req) => Requirement.fromJson(req as Map<String, dynamic>))
          .toList(),
      prioritizedRequirements: prioritizedRequirements,
    );
  }

  bool get hasPrioritizedResults => prioritizedRequirements.isNotEmpty;

  @override
  List<Object?> get props => [
        sessionId,
        name,
        createdAt,
        updatedAt,
        requirements,
        prioritizedRequirements,
      ];
}

