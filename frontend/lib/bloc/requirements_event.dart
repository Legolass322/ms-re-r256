import 'package:equatable/equatable.dart';
import 'dart:io';
import 'dart:typed_data';
import '../models/requirement.dart';
import '../models/prioritized_requirement.dart';

abstract class RequirementsEvent extends Equatable {
  const RequirementsEvent();

  @override
  List<Object?> get props => [];
}

class UploadFileEvent extends RequirementsEvent {
  final Uint8List bytes;
  final String filename;

  const UploadFileEvent({
    required this.bytes,
    required this.filename,
  });

  @override
  List<Object?> get props => [bytes, filename];
}

class CreateRequirementsEvent extends RequirementsEvent {
  final List<Requirement> requirements;

  const CreateRequirementsEvent(this.requirements);

  @override
  List<Object?> get props => [requirements];
}

class AnalyzePrioritizationEvent extends RequirementsEvent {
  final String sessionId;
  final Map<String, double>? weights;

  const AnalyzePrioritizationEvent({required this.sessionId, this.weights});

  @override
  List<Object?> get props => [sessionId, weights];
}

class GetPrioritizationEvent extends RequirementsEvent {
  final String sessionId;

  const GetPrioritizationEvent(this.sessionId);

  @override
  List<Object?> get props => [sessionId];
}

class ExportCsvEvent extends RequirementsEvent {
  final String sessionId;

  const ExportCsvEvent(this.sessionId);

  @override
  List<Object?> get props => [sessionId];
}

class ExportHtmlEvent extends RequirementsEvent {
  final String sessionId;

  const ExportHtmlEvent(this.sessionId);

  @override
  List<Object?> get props => [sessionId];
}

class ExportPdfEvent extends RequirementsEvent {
  final String sessionId;
  final List<PrioritizedRequirement> requirements;

  const ExportPdfEvent(this.sessionId, this.requirements);

  @override
  List<Object?> get props => [sessionId, requirements];
}

class ResetEvent extends RequirementsEvent {
  const ResetEvent();
}

class RestoreLatestSessionEvent extends RequirementsEvent {
  const RestoreLatestSessionEvent();
}

class ChatGPTAnalyzeEvent extends RequirementsEvent {
  final String sessionId;
  final String? prompt;

  const ChatGPTAnalyzeEvent({
    required this.sessionId,
    this.prompt,
  });

  @override
  List<Object?> get props => [sessionId, prompt];
}
