// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'requirement.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Requirement _$RequirementFromJson(Map<String, dynamic> json) => Requirement(
  id: json['id'] as String,
  title: json['title'] as String,
  description: json['description'] as String,
  businessValue: (json['businessValue'] as num?)?.toDouble(),
  cost: (json['cost'] as num?)?.toDouble(),
  risk: (json['risk'] as num?)?.toDouble(),
  urgency: (json['urgency'] as num?)?.toDouble(),
  stakeholderValue: (json['stakeholderValue'] as num?)?.toDouble(),
  category: $enumDecodeNullable(_$RequirementCategoryEnumMap, json['category']),
);

Map<String, dynamic> _$RequirementToJson(Requirement instance) {
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
