import 'dart:typed_data';

import 'package:equatable/equatable.dart';
import '../models/requirement.dart';
import '../models/prioritized_requirement.dart';
import '../models/api_response.dart';

abstract class RequirementsState extends Equatable {
  const RequirementsState();

  @override
  List<Object?> get props => [];
}

class RequirementsInitial extends RequirementsState {
  const RequirementsInitial();
}

class RequirementsLoading extends RequirementsState {
  final String? message;

  const RequirementsLoading({this.message});

  @override
  List<Object?> get props => [message];
}

class RequirementsUploaded extends RequirementsState {
  final String sessionId;
  final List<Requirement> requirements;
  final String message;

  const RequirementsUploaded({
    required this.sessionId,
    required this.requirements,
    required this.message,
  });

  @override
  List<Object?> get props => [sessionId, requirements, message];
}

class RequirementsCreated extends RequirementsState {
  final String sessionId;
  final int count;
  final String message;

  const RequirementsCreated({
    required this.sessionId,
    required this.count,
    required this.message,
  });

  @override
  List<Object?> get props => [sessionId, count, message];
}

class PrioritizationAnalyzing extends RequirementsState {
  final String sessionId;

  const PrioritizationAnalyzing(this.sessionId);

  @override
  List<Object?> get props => [sessionId];
}

class PrioritizationComplete extends RequirementsState {
  final String sessionId;
  final List<PrioritizedRequirement> prioritizedRequirements;
  final int processingTimeMs;
  final PrioritizationMetadata? metadata;

  const PrioritizationComplete({
    required this.sessionId,
    required this.prioritizedRequirements,
    required this.processingTimeMs,
    this.metadata,
  });

  @override
  List<Object?> get props => [
    sessionId,
    prioritizedRequirements,
    processingTimeMs,
    metadata,
  ];
}

class WorkspaceLoaded extends RequirementsState {
  final String sessionId;
  final String? name;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final List<Requirement> requirements;
  final List<PrioritizedRequirement> prioritizedRequirements;

  const WorkspaceLoaded({
    required this.sessionId,
    this.name,
    required this.createdAt,
    this.updatedAt,
    required this.requirements,
    required this.prioritizedRequirements,
  });

  bool get hasRequirements => requirements.isNotEmpty;
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

class ExportSuccess extends RequirementsState {
  final String format;
  final String? data;
  final Uint8List? bytes;

  const ExportSuccess({
    required this.format,
    this.data,
    this.bytes,
  });

  @override
  List<Object?> get props => [format, data, bytes];
}

class ChatGPTAnalysisComplete extends RequirementsState {
  final String sessionId;
  final String summary;

  const ChatGPTAnalysisComplete({
    required this.sessionId,
    required this.summary,
  });

  @override
  List<Object?> get props => [sessionId, summary];
}

class RequirementsError extends RequirementsState {
  final String message;
  final String? details;

  const RequirementsError({required this.message, this.details});

  @override
  List<Object?> get props => [message, details];
}
