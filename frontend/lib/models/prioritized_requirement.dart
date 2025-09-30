import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/equatable.dart';
import 'requirement.dart';

part 'prioritized_requirement.g.dart';

@JsonSerializable()
class PrioritizedRequirement extends Equatable {
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

  factory PrioritizedRequirement.fromJson(Map<String, dynamic> json) =>
      _$PrioritizedRequirementFromJson(json);

  Map<String, dynamic> toJson() => _$PrioritizedRequirementToJson(this);

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
    priorityScore,
    rank,
    confidence,
    reasoning,
  ];
}
