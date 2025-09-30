import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/equatable.dart';

part 'requirement.g.dart';

enum RequirementCategory {
  @JsonValue('FEATURE')
  feature,
  @JsonValue('ENHANCEMENT')
  enhancement,
  @JsonValue('BUG_FIX')
  bugFix,
  @JsonValue('TECHNICAL')
  technical,
  @JsonValue('COMPLIANCE')
  compliance,
}

@JsonSerializable()
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

  factory Requirement.fromJson(Map<String, dynamic> json) =>
      _$RequirementFromJson(json);

  Map<String, dynamic> toJson() => _$RequirementToJson(this);

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
