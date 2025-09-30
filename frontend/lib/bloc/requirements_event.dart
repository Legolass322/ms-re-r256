import 'package:equatable/equatable.dart';
import 'dart:io';
import '../models/requirement.dart';

abstract class RequirementsEvent extends Equatable {
  const RequirementsEvent();

  @override
  List<Object?> get props => [];
}

class UploadFileEvent extends RequirementsEvent {
  final File file;

  const UploadFileEvent(this.file);

  @override
  List<Object?> get props => [file];
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

class ResetEvent extends RequirementsEvent {
  const ResetEvent();
}
