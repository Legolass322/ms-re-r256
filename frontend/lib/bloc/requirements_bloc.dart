import 'package:flutter_bloc/flutter_bloc.dart';
import 'requirements_event.dart';
import 'requirements_state.dart';
import '../api/aria_api_client.dart';

class RequirementsBloc extends Bloc<RequirementsEvent, RequirementsState> {
  final AriaApiClient apiClient;

  RequirementsBloc({required this.apiClient})
    : super(const RequirementsInitial()) {
    on<UploadFileEvent>(_onUploadFile);
    on<CreateRequirementsEvent>(_onCreateRequirements);
    on<AnalyzePrioritizationEvent>(_onAnalyzePrioritization);
    on<GetPrioritizationEvent>(_onGetPrioritization);
    on<ExportCsvEvent>(_onExportCsv);
    on<ExportHtmlEvent>(_onExportHtml);
    on<ResetEvent>(_onReset);
  }

  Future<void> _onUploadFile(
    UploadFileEvent event,
    Emitter<RequirementsState> emit,
  ) async {
    try {
      emit(const RequirementsLoading(message: 'Uploading file...'));

      final response = await apiClient.uploadRequirements(event.file);

      emit(
        RequirementsUploaded(
          sessionId: response.sessionId,
          requirements: response.requirements ?? [],
          message: response.message,
        ),
      );
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
      emit(PrioritizationAnalyzing(event.sessionId));

      final response = await apiClient.analyzePrioritization(
        sessionId: event.sessionId,
        weights: event.weights,
      );

      emit(
        PrioritizationComplete(
          sessionId: response.sessionId,
          prioritizedRequirements: response.prioritizedRequirements,
          processingTimeMs: response.processingTimeMs,
          metadata: response.metadata,
        ),
      );
    } catch (e) {
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
    emit(const RequirementsInitial());
  }
}
