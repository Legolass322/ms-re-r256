import 'requirement.dart';

// Removed @JsonSerializable(), fromJson/toJson, and Equatable inheritance to avoid type errors in Flutter Web
// All deserialization is now done manually in aria_api_client.dart
class PrioritizedRequirement {
  final String id;
  final String title;
  final String description;
  final double? businessValue;
  final double? cost;
  final double? risk;
  final double? urgency;
  final double? stakeholderValue;
  final RequirementCategory? category;
  final double priorityScore;
  final int rank;
  final double? confidence;
  final String? reasoning;

  const PrioritizedRequirement({
    required this.id,
    required this.title,
    required this.description,
    this.businessValue,
    this.cost,
    this.risk,
    this.urgency,
    this.stakeholderValue,
    this.category,
    required this.priorityScore,
    required this.rank,
    this.confidence,
    this.reasoning,
  });

  Map<String, dynamic> toJson() {
    String? categoryToString(RequirementCategory? category) {
      if (category == null) return null;
      switch (category) {
        case RequirementCategory.feature:
          return 'FEATURE';
        case RequirementCategory.enhancement:
          return 'ENHANCEMENT';
        case RequirementCategory.bugFix:
          return 'BUG_FIX';
        case RequirementCategory.technical:
          return 'TECHNICAL';
        case RequirementCategory.compliance:
          return 'COMPLIANCE';
      }
    }

    return {
      'id': id,
      'title': title,
      'description': description,
      if (businessValue != null) 'businessValue': businessValue,
      if (cost != null) 'cost': cost,
      if (risk != null) 'risk': risk,
      if (urgency != null) 'urgency': urgency,
      if (stakeholderValue != null) 'stakeholderValue': stakeholderValue,
      if (category != null) 'category': categoryToString(category),
      'priorityScore': priorityScore,
      'rank': rank,
      if (confidence != null) 'confidence': confidence,
      if (reasoning != null && reasoning!.isNotEmpty) 'reasoning': reasoning,
    };
  }

  // Removed fromJson methods and Equatable - use manual deserialization in aria_api_client.dart
  // Removed props getter as we no longer extend Equatable
}
