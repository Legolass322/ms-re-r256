import 'dart:developer' as developer;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'requirements_event.dart';
import 'requirements_state.dart';
import '../api/aria_api_client.dart';
import '../models/session_details.dart';

class RequirementsBloc extends Bloc<RequirementsEvent, RequirementsState> {
  final AriaApiClient apiClient;
  SessionDetails? _workspace;
  SessionDetails? get workspace => _workspace;

  RequirementsBloc({required this.apiClient})
    : super(const RequirementsInitial()) {
    on<UploadFileEvent>(_onUploadFile);
    on<CreateRequirementsEvent>(_onCreateRequirements);
    on<AnalyzePrioritizationEvent>(_onAnalyzePrioritization);
    on<GetPrioritizationEvent>(_onGetPrioritization);
    on<ExportCsvEvent>(_onExportCsv);
    on<ExportHtmlEvent>(_onExportHtml);
    on<ResetEvent>(_onReset);
    on<RestoreLatestSessionEvent>(_onRestoreLatestSession);
    on<ChatGPTAnalyzeEvent>(_onChatGPTAnalyze);
  }

  Future<void> _onUploadFile(
    UploadFileEvent event,
    Emitter<RequirementsState> emit,
  ) async {
    try {
      emit(const RequirementsLoading(message: 'Uploading file...'));

      final response = await apiClient.uploadRequirements(
        bytes: event.bytes,
        filename: event.filename,
      );

      emit(
        RequirementsUploaded(
          sessionId: response.sessionId,
          requirements: response.requirements ?? [],
          message: response.message,
        ),
      );
      add(const RestoreLatestSessionEvent());
    } catch (e) {
      emit(
        RequirementsError(
          message: 'Failed to upload file',
          details: e.toString(),
        ),
      );
    }
  }

  Future<void> _onCreateRequirements(
    CreateRequirementsEvent event,
    Emitter<RequirementsState> emit,
  ) async {
    try {
      emit(const RequirementsLoading(message: 'Creating requirements...'));

      final response = await apiClient.createRequirements(event.requirements);

      emit(
        RequirementsCreated(
          sessionId: response.sessionId,
          count: response.requirementsCount,
          message: response.message ?? 'Requirements created successfully',
        ),
      );
      add(const RestoreLatestSessionEvent());
    } catch (e) {
      emit(
        RequirementsError(
          message: 'Failed to create requirements',
          details: e.toString(),
        ),
      );
    }
  }

  Future<void> _onAnalyzePrioritization(
    AnalyzePrioritizationEvent event,
    Emitter<RequirementsState> emit,
  ) async {
    try {
      developer.log('DEBUG: Starting prioritization analysis for session: ${event.sessionId}', name: 'RequirementsBloc');
      emit(PrioritizationAnalyzing(event.sessionId));

      developer.log('DEBUG: Calling apiClient.analyzePrioritization...', name: 'RequirementsBloc');
      final response = await apiClient.analyzePrioritization(
        sessionId: event.sessionId,
        weights: event.weights,
      );

      developer.log('DEBUG: Analysis complete. SessionId: ${response.sessionId}, Requirements count: ${response.prioritizedRequirements.length}', name: 'RequirementsBloc');
      
      // Validate requirements before emitting
      if (response.prioritizedRequirements.isEmpty) {
        developer.log('ERROR: Response has empty prioritizedRequirements list', name: 'RequirementsBloc');
        emit(
          RequirementsError(
            message: 'Analysis completed but no requirements were prioritized',
            details: 'Response contained 0 prioritized requirements',
          ),
        );
        return;
      }
      
      // Log first requirement for debugging
      if (response.prioritizedRequirements.isNotEmpty) {
        final firstReq = response.prioritizedRequirements[0];
        developer.log('DEBUG: First requirement: id=${firstReq.id}, title=${firstReq.title}, score=${firstReq.priorityScore}, rank=${firstReq.rank}', name: 'RequirementsBloc');
      }
      
      emit(
        PrioritizationComplete(
          sessionId: response.sessionId,
          prioritizedRequirements: response.prioritizedRequirements,
          processingTimeMs: response.processingTimeMs,
          metadata: response.metadata,
        ),
      );
      developer.log('DEBUG: PrioritizationComplete state emitted with ${response.prioritizedRequirements.length} requirements', name: 'RequirementsBloc');
      add(const RestoreLatestSessionEvent());
    } catch (e, stackTrace) {
      developer.log('ERROR in _onAnalyzePrioritization: $e', name: 'RequirementsBloc', error: e, stackTrace: stackTrace);
      emit(
        RequirementsError(
          message: 'Failed to analyze prioritization',
          details: e.toString(),
        ),
      );
    }
  }

  Future<void> _onGetPrioritization(
    GetPrioritizationEvent event,
    Emitter<RequirementsState> emit,
  ) async {
    try {
      emit(const RequirementsLoading(message: 'Loading results...'));

      final response = await apiClient.getPrioritization(event.sessionId);

      emit(
        PrioritizationComplete(
          sessionId: response.sessionId,
          prioritizedRequirements: response.prioritizedRequirements,
          processingTimeMs: response.processingTimeMs,
          metadata: response.metadata,
        ),
      );
      add(const RestoreLatestSessionEvent());
    } catch (e) {
      emit(
        RequirementsError(
          message: 'Failed to load prioritization',
          details: e.toString(),
        ),
      );
    }
  }

  Future<void> _onExportCsv(
    ExportCsvEvent event,
    Emitter<RequirementsState> emit,
  ) async {
    try {
      emit(const RequirementsLoading(message: 'Exporting to CSV...'));

      final csvData = await apiClient.exportCsv(event.sessionId);

      emit(ExportSuccess(data: csvData, format: 'csv'));
    } catch (e) {
      emit(
        RequirementsError(
          message: 'Failed to export CSV',
          details: e.toString(),
        ),
      );
    }
  }

  Future<void> _onExportHtml(
    ExportHtmlEvent event,
    Emitter<RequirementsState> emit,
  ) async {
    try {
      emit(const RequirementsLoading(message: 'Exporting to HTML...'));

      final htmlData = await apiClient.exportHtml(event.sessionId);

      emit(ExportSuccess(data: htmlData, format: 'html'));
    } catch (e) {
      emit(
        RequirementsError(
          message: 'Failed to export HTML',
          details: e.toString(),
        ),
      );
    }
  }

  Future<void> _onReset(
    ResetEvent event,
    Emitter<RequirementsState> emit,
  ) async {
    _workspace = null;
    emit(const RequirementsInitial());
  }

  Future<void> _onRestoreLatestSession(
    RestoreLatestSessionEvent event,
    Emitter<RequirementsState> emit,
  ) async {
    final shouldShowLoader = state is RequirementsInitial;
    if (shouldShowLoader) {
      emit(const RequirementsLoading(message: 'Restoring workspace...'));
    }

    try {
      final session = await apiClient.getLatestSession();
      if (session == null ||
          (session.requirements.isEmpty &&
              session.prioritizedRequirements.isEmpty)) {
        _workspace = null;
        emit(const RequirementsInitial());
        return;
      }

      _workspace = session;
      emit(
        WorkspaceLoaded(
          sessionId: session.sessionId,
          name: session.name,
          createdAt: session.createdAt,
          updatedAt: session.updatedAt,
          requirements: session.requirements,
          prioritizedRequirements: session.prioritizedRequirements,
        ),
      );
    } catch (e) {
      emit(
        RequirementsError(
          message: 'Failed to restore workspace',
          details: e.toString(),
        ),
      );
    }
  }

  Future<void> _onChatGPTAnalyze(
    ChatGPTAnalyzeEvent event,
    Emitter<RequirementsState> emit,
  ) async {
    emit(const RequirementsLoading(message: 'Consulting ChatGPT...'));
    try {
      final summary = await apiClient.analyzeWithChatGPT(
        sessionId: event.sessionId,
        prompt: event.prompt,
      );
      emit(
        ChatGPTAnalysisComplete(
          sessionId: event.sessionId,
          summary: summary,
        ),
      );
      add(const RestoreLatestSessionEvent());
    } catch (e) {
      emit(
        RequirementsError(
          message: 'Failed to analyze with ChatGPT',
          details: e.toString(),
        ),
      );
    }
  }
}
