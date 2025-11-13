import 'package:equatable/equatable.dart';
import 'requirement.dart';
import 'prioritized_requirement.dart';

// Removed part 'api_response.g.dart' and @JsonSerializable() to avoid type errors in Flutter Web
// All parsing is now done manually in aria_api_client.dart

// Removed @JsonSerializable() to avoid type errors in Flutter Web
// Manual parsing in aria_api_client.dart
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

  // Manual fromJson - see aria_api_client.dart
  // Removed toJson - not needed

  @override
  List<Object?> get props => [
    sessionId,
    requirementsCount,
    message,
    requirements,
  ];
}

// Removed @JsonSerializable() to avoid type errors in Flutter Web
// Manual toJson for sending requests
class CreateRequirementsRequest extends Equatable {
  final List<Requirement> requirements;

  const CreateRequirementsRequest({required this.requirements});

  Map<String, dynamic> toJson() {
    return {
      'requirements': requirements.map((req) => req.toJson()).toList(),
    };
  }

  @override
  List<Object?> get props => [requirements];
}

// Removed @JsonSerializable() to avoid type errors in Flutter Web
// Manual parsing in aria_api_client.dart
class CreateRequirementsResponse extends Equatable {
  final String sessionId;
  final int requirementsCount;
  final String? message;

  const CreateRequirementsResponse({
    required this.sessionId,
    required this.requirementsCount,
    this.message,
  });

  // Manual fromJson - see aria_api_client.dart
  // Removed toJson - not needed

  @override
  List<Object?> get props => [sessionId, requirementsCount, message];
}

// Removed @JsonSerializable() to avoid type errors in Flutter Web
// Manual toJson for sending requests
class PrioritizationRequest extends Equatable {
  final String sessionId;
  final Map<String, double>? weights;

  const PrioritizationRequest({required this.sessionId, this.weights});

  Map<String, dynamic> toJson() {
    return {
      'sessionId': sessionId,
      if (weights != null) 'weights': weights,
    };
  }

  @override
  List<Object?> get props => [sessionId, weights];
}

// Removed @JsonSerializable() to avoid type errors in Flutter Web
// All deserialization is now done manually in aria_api_client.dart
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

  // Removed fromJson/toJson methods - use manual deserialization in aria_api_client.dart

  @override
  List<Object?> get props => [
    totalRequirements,
    averageScore,
    modelVersion,
    weightsUsed,
  ];
}

// Removed @JsonSerializable() to avoid type errors in Flutter Web
// All deserialization is now done manually in aria_api_client.dart
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

  // Removed fromJson/toJson methods - use manual deserialization in aria_api_client.dart

  @override
  List<Object?> get props => [
    sessionId,
    prioritizedRequirements,
    processingTimeMs,
    metadata,
  ];
}

// Removed @JsonSerializable() to avoid type errors in Flutter Web
// Manual parsing in aria_api_client.dart
class ApiError extends Equatable {
  final String error;
  final String message;
  final Map<String, dynamic>? details;

  const ApiError({required this.error, required this.message, this.details});

  // Manual fromJson - see aria_api_client.dart
  // Removed toJson - not needed

  @override
  List<Object?> get props => [error, message, details];
}
