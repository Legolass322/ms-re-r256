import 'dart:io';
import 'package:dio/dio.dart';
import '../models/requirement.dart';
import '../models/api_response.dart';

class AriaApiClient {
  final Dio _dio;
  final String baseUrl;

  AriaApiClient({String? baseUrl, Dio? dio})
    : baseUrl = baseUrl ?? 'http://localhost:8080/v1',
      _dio = dio ?? Dio() {
    _dio.options.baseUrl = this.baseUrl;
    _dio.options.connectTimeout = const Duration(seconds: 30);
    _dio.options.receiveTimeout = const Duration(seconds: 30);
    _dio.interceptors.add(
      LogInterceptor(requestBody: true, responseBody: true),
    );
  }

  /// Upload requirements from CSV/Excel file
  Future<UploadResponse> uploadRequirements(File file) async {
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          file.path,
          filename: file.path.split('/').last,
        ),
      });

      final response = await _dio.post('/requirements/upload', data: formData);

      return UploadResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Create requirements manually
  Future<CreateRequirementsResponse> createRequirements(
    List<Requirement> requirements,
  ) async {
    try {
      final request = CreateRequirementsRequest(requirements: requirements);
      final response = await _dio.post('/requirements', data: request.toJson());

      return CreateRequirementsResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Get all requirements for a session
  Future<List<Requirement>> getRequirements(String sessionId) async {
    try {
      final response = await _dio.get(
        '/requirements',
        queryParameters: {'sessionId': sessionId},
      );

      final data = response.data as Map<String, dynamic>;
      final requirementsList = data['requirements'] as List;
      return requirementsList
          .map((json) => Requirement.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Analyze and prioritize requirements
  Future<PrioritizationResponse> analyzePrioritization({
    required String sessionId,
    Map<String, double>? weights,
  }) async {
    try {
      final request = PrioritizationRequest(
        sessionId: sessionId,
        weights: weights,
      );

      final response = await _dio.post(
        '/prioritization/analyze',
        data: request.toJson(),
      );

      return PrioritizationResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Get prioritization results
  Future<PrioritizationResponse> getPrioritization(String sessionId) async {
    try {
      final response = await _dio.get('/prioritization/$sessionId');
      return PrioritizationResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Export results as CSV
  Future<String> exportCsv(String sessionId) async {
    try {
      final response = await _dio.get(
        '/export/csv/$sessionId',
        options: Options(responseType: ResponseType.plain),
      );
      return response.data as String;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Export results as HTML report
  Future<String> exportHtml(String sessionId) async {
    try {
      final response = await _dio.get(
        '/export/html/$sessionId',
        options: Options(responseType: ResponseType.plain),
      );
      return response.data as String;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Health check
  Future<bool> healthCheck() async {
    try {
      final response = await _dio.get('/health');
      return response.data['status'] == 'healthy';
    } catch (e) {
      return false;
    }
  }

  Exception _handleError(DioException error) {
    if (error.response?.data != null) {
      try {
        final apiError = ApiError.fromJson(error.response!.data);
        return Exception('${apiError.error}: ${apiError.message}');
      } catch (_) {
        return Exception(error.message);
      }
    }
    return Exception(error.message);
  }
}
