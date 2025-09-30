import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/equatable.dart';
import 'requirement.dart';
import 'prioritized_requirement.dart';

part 'api_response.g.dart';

@JsonSerializable()
class UploadResponse extends Equatable {
  final String sessionId;
  final int requirementsCount;
  final String message;
  final List<Requirement>? requirements;

  const UploadResponse({
    required this.sessionId,
    required this.requirementsCount,
    required this.message,
    this.requirements,
  });

  factory UploadResponse.fromJson(Map<String, dynamic> json) =>
      _$UploadResponseFromJson(json);

  Map<String, dynamic> toJson() => _$UploadResponseToJson(this);

  @override
  List<Object?> get props => [
    sessionId,
    requirementsCount,
    message,
    requirements,
  ];
}

@JsonSerializable()
class CreateRequirementsRequest extends Equatable {
  final List<Requirement> requirements;

  const CreateRequirementsRequest({required this.requirements});

  factory CreateRequirementsRequest.fromJson(Map<String, dynamic> json) =>
      _$CreateRequirementsRequestFromJson(json);

  Map<String, dynamic> toJson() => _$CreateRequirementsRequestToJson(this);

  @override
  List<Object?> get props => [requirements];
}

@JsonSerializable()
class CreateRequirementsResponse extends Equatable {
  final String sessionId;
  final int requirementsCount;
  final String? message;

  const CreateRequirementsResponse({
    required this.sessionId,
    required this.requirementsCount,
    this.message,
  });

  factory CreateRequirementsResponse.fromJson(Map<String, dynamic> json) =>
      _$CreateRequirementsResponseFromJson(json);

  Map<String, dynamic> toJson() => _$CreateRequirementsResponseToJson(this);

  @override
  List<Object?> get props => [sessionId, requirementsCount, message];
}

@JsonSerializable()
class PrioritizationRequest extends Equatable {
  final String sessionId;
  final Map<String, double>? weights;

  const PrioritizationRequest({required this.sessionId, this.weights});

  factory PrioritizationRequest.fromJson(Map<String, dynamic> json) =>
      _$PrioritizationRequestFromJson(json);

  Map<String, dynamic> toJson() => _$PrioritizationRequestToJson(this);

  @override
  List<Object?> get props => [sessionId, weights];
}

@JsonSerializable()
class PrioritizationMetadata extends Equatable {
  final int? totalRequirements;
  final double? averageScore;
  final String? modelVersion;
  final Map<String, double>? weightsUsed;

  const PrioritizationMetadata({
    this.totalRequirements,
    this.averageScore,
    this.modelVersion,
    this.weightsUsed,
  });

  factory PrioritizationMetadata.fromJson(Map<String, dynamic> json) =>
      _$PrioritizationMetadataFromJson(json);

  Map<String, dynamic> toJson() => _$PrioritizationMetadataToJson(this);

  @override
  List<Object?> get props => [
    totalRequirements,
    averageScore,
    modelVersion,
    weightsUsed,
  ];
}

@JsonSerializable()
class PrioritizationResponse extends Equatable {
  final String sessionId;
  final List<PrioritizedRequirement> prioritizedRequirements;
  final int processingTimeMs;
  final PrioritizationMetadata? metadata;

  const PrioritizationResponse({
    required this.sessionId,
    required this.prioritizedRequirements,
    required this.processingTimeMs,
    this.metadata,
  });

  factory PrioritizationResponse.fromJson(Map<String, dynamic> json) =>
      _$PrioritizationResponseFromJson(json);

  Map<String, dynamic> toJson() => _$PrioritizationResponseToJson(this);

  @override
  List<Object?> get props => [
    sessionId,
    prioritizedRequirements,
    processingTimeMs,
    metadata,
  ];
}

@JsonSerializable()
class ApiError extends Equatable {
  final String error;
  final String message;
  final Map<String, dynamic>? details;

  const ApiError({required this.error, required this.message, this.details});

  factory ApiError.fromJson(Map<String, dynamic> json) =>
      _$ApiErrorFromJson(json);

  Map<String, dynamic> toJson() => _$ApiErrorToJson(this);

  @override
  List<Object?> get props => [error, message, details];
}
