// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'prioritized_requirement.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PrioritizedRequirement _$PrioritizedRequirementFromJson(
  Map<String, dynamic> json,
) => PrioritizedRequirement(
  id: json['id'] as String,
  title: json['title'] as String,
  description: json['description'] as String,
  businessValue: (json['businessValue'] as num?)?.toDouble(),
  cost: (json['cost'] as num?)?.toDouble(),
  risk: (json['risk'] as num?)?.toDouble(),
  urgency: (json['urgency'] as num?)?.toDouble(),
  stakeholderValue: (json['stakeholderValue'] as num?)?.toDouble(),
  category: $enumDecodeNullable(_$RequirementCategoryEnumMap, json['category']),
  priorityScore: (json['priorityScore'] as num).toDouble(),
  rank: json['rank'] as int,
  confidence: (json['confidence'] as num?)?.toDouble(),
  reasoning: json['reasoning'] as String?,
);

Map<String, dynamic> _$PrioritizedRequirementToJson(
  PrioritizedRequirement instance,
) {
  final val = <String, dynamic>{
    'id': instance.id,
    'title': instance.title,
    'description': instance.description,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('businessValue', instance.businessValue);
  writeNotNull('cost', instance.cost);
  writeNotNull('risk', instance.risk);
  writeNotNull('urgency', instance.urgency);
  writeNotNull('stakeholderValue', instance.stakeholderValue);
  writeNotNull('category', _$RequirementCategoryEnumMap[instance.category]);
  val['priorityScore'] = instance.priorityScore;
  val['rank'] = instance.rank;
  writeNotNull('confidence', instance.confidence);
  writeNotNull('reasoning', instance.reasoning);
  return val;
}

const _$RequirementCategoryEnumMap = {
  RequirementCategory.feature: 'FEATURE',
  RequirementCategory.enhancement: 'ENHANCEMENT',
  RequirementCategory.bugFix: 'BUG_FIX',
  RequirementCategory.technical: 'TECHNICAL',
  RequirementCategory.compliance: 'COMPLIANCE',
};

T? $enumDecodeNullable<T>(Map<T, dynamic> enumValues, dynamic source) {
  if (source == null) {
    return null;
  }
  return enumValues.entries
      .singleWhere(
        (e) => e.value == source,
        orElse: () => throw ArgumentError('Unknown enum value'),
      )
      .key;
}
