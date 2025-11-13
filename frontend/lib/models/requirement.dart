import 'package:equatable/equatable.dart';

// Removed @JsonSerializable() and part 'requirement.g.dart' to avoid type errors in Flutter Web
// Manual parsing is done in aria_api_client.dart and session_details.dart

enum RequirementCategory {
  feature,
  enhancement,
  bugFix,
  technical,
  compliance,
}

class Requirement extends Equatable {
  final String id;
  final String title;
  final String description;
  final double? businessValue;
  final double? cost;
  final double? risk;
  final double? urgency;
  final double? stakeholderValue;
  final RequirementCategory? category;

  const Requirement({
    required this.id,
    required this.title,
    required this.description,
    this.businessValue,
    this.cost,
    this.risk,
    this.urgency,
    this.stakeholderValue,
    this.category,
  });

  // Manual fromJson - see aria_api_client.dart and session_details.dart
  factory Requirement.fromJson(Map<String, dynamic> json) {
    // Helper to parse doubles
    double? parseDouble(dynamic value) {
      if (value == null) return null;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is num) return value.toDouble();
      return double.tryParse(value.toString());
    }
    
    // Parse category
    RequirementCategory? parseCategory(String? categoryStr) {
      if (categoryStr == null || categoryStr.isEmpty) return null;
      final normalized = categoryStr.toUpperCase().replaceAll('_', '');
      try {
        return RequirementCategory.values.firstWhere(
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
      } catch (_) {
        return null;
      }
    }
    
    return Requirement(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      businessValue: parseDouble(json['businessValue']),
      cost: parseDouble(json['cost']),
      risk: parseDouble(json['risk']),
      urgency: parseDouble(json['urgency']),
      stakeholderValue: parseDouble(json['stakeholderValue']),
      category: parseCategory(json['category']?.toString()),
    );
  }

  // Manual toJson for sending requests
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
    };
  }

  Requirement copyWith({
    String? id,
    String? title,
    String? description,
    double? businessValue,
    double? cost,
    double? risk,
    double? urgency,
    double? stakeholderValue,
    RequirementCategory? category,
  }) {
    return Requirement(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      businessValue: businessValue ?? this.businessValue,
      cost: cost ?? this.cost,
      risk: risk ?? this.risk,
      urgency: urgency ?? this.urgency,
      stakeholderValue: stakeholderValue ?? this.stakeholderValue,
      category: category ?? this.category,
    );
  }

  @override
  List<Object?> get props => [
    id,
    title,
    description,
    businessValue,
    cost,
    risk,
    urgency,
    stakeholderValue,
    category,
  ];
}
