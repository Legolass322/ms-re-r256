// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'api_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UploadResponse _$UploadResponseFromJson(Map<String, dynamic> json) =>
    UploadResponse(
      sessionId: json['sessionId'] as String,
      requirementsCount: json['requirementsCount'] as int,
      message: json['message'] as String,
      requirements: (json['requirements'] as List<dynamic>?)
          ?.map((e) => Requirement.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$UploadResponseToJson(UploadResponse instance) {
  final val = <String, dynamic>{
    'sessionId': instance.sessionId,
    'requirementsCount': instance.requirementsCount,
    'message': instance.message,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull(
    'requirements',
    instance.requirements?.map((e) => e.toJson()).toList(),
  );
  return val;
}

CreateRequirementsRequest _$CreateRequirementsRequestFromJson(
  Map<String, dynamic> json,
) => CreateRequirementsRequest(
  requirements: (json['requirements'] as List<dynamic>)
      .map((e) => Requirement.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$CreateRequirementsRequestToJson(
  CreateRequirementsRequest instance,
) => <String, dynamic>{
  'requirements': instance.requirements.map((e) => e.toJson()).toList(),
};

CreateRequirementsResponse _$CreateRequirementsResponseFromJson(
  Map<String, dynamic> json,
) => CreateRequirementsResponse(
  sessionId: json['sessionId'] as String,
  requirementsCount: json['requirementsCount'] as int,
  message: json['message'] as String?,
);

Map<String, dynamic> _$CreateRequirementsResponseToJson(
  CreateRequirementsResponse instance,
) {
  final val = <String, dynamic>{
    'sessionId': instance.sessionId,
    'requirementsCount': instance.requirementsCount,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('message', instance.message);
  return val;
}

PrioritizationRequest _$PrioritizationRequestFromJson(
  Map<String, dynamic> json,
) => PrioritizationRequest(
  sessionId: json['sessionId'] as String,
  weights: (json['weights'] as Map<String, dynamic>?)?.map(
    (k, e) => MapEntry(k, (e as num).toDouble()),
  ),
);

Map<String, dynamic> _$PrioritizationRequestToJson(
  PrioritizationRequest instance,
) {
  final val = <String, dynamic>{'sessionId': instance.sessionId};

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('weights', instance.weights);
  return val;
}

PrioritizationMetadata _$PrioritizationMetadataFromJson(
  Map<String, dynamic> json,
) => PrioritizationMetadata(
  totalRequirements: json['totalRequirements'] as int?,
  averageScore: (json['averageScore'] as num?)?.toDouble(),
  modelVersion: json['modelVersion'] as String?,
  weightsUsed: (json['weightsUsed'] as Map<String, dynamic>?)?.map(
    (k, e) => MapEntry(k, (e as num).toDouble()),
  ),
);

Map<String, dynamic> _$PrioritizationMetadataToJson(
  PrioritizationMetadata instance,
) {
  final val = <String, dynamic>{};

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('totalRequirements', instance.totalRequirements);
  writeNotNull('averageScore', instance.averageScore);
  writeNotNull('modelVersion', instance.modelVersion);
  writeNotNull('weightsUsed', instance.weightsUsed);
  return val;
}

PrioritizationResponse _$PrioritizationResponseFromJson(
  Map<String, dynamic> json,
) => PrioritizationResponse(
  sessionId: json['sessionId'] as String,
  prioritizedRequirements: (json['prioritizedRequirements'] as List<dynamic>)
      .map((e) => PrioritizedRequirement.fromJson(e as Map<String, dynamic>))
      .toList(),
  processingTimeMs: json['processingTimeMs'] as int,
  metadata: json['metadata'] == null
      ? null
      : PrioritizationMetadata.fromJson(
          json['metadata'] as Map<String, dynamic>,
        ),
);

Map<String, dynamic> _$PrioritizationResponseToJson(
  PrioritizationResponse instance,
) {
  final val = <String, dynamic>{
    'sessionId': instance.sessionId,
    'prioritizedRequirements': instance.prioritizedRequirements
        .map((e) => e.toJson())
        .toList(),
    'processingTimeMs': instance.processingTimeMs,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('metadata', instance.metadata?.toJson());
  return val;
}

ApiError _$ApiErrorFromJson(Map<String, dynamic> json) => ApiError(
  error: json['error'] as String,
  message: json['message'] as String,
  details: json['details'] as Map<String, dynamic>?,
);

Map<String, dynamic> _$ApiErrorToJson(ApiError instance) {
  final val = <String, dynamic>{
    'error': instance.error,
    'message': instance.message,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('details', instance.details);
  return val;
}
