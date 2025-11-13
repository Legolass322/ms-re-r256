import 'dart:developer' as developer;
import 'dart:typed_data';

import 'package:dio/dio.dart';
import '../models/requirement.dart';
import '../models/api_response.dart';
import '../models/auth_models.dart';
import '../models/session_details.dart';
import '../models/prioritized_requirement.dart';

const String _defaultApiUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://localhost:8080',
);

class AriaApiClient {
  final Dio _dio;
  final String baseUrl;
  String? _authToken;

  AriaApiClient({String? baseUrl, Dio? dio})
    : baseUrl = baseUrl ?? _defaultApiUrl,
      _dio = dio ?? Dio() {
    _dio.options.baseUrl = this.baseUrl;
    _dio.options.connectTimeout = const Duration(seconds: 30);
    _dio.options.receiveTimeout = const Duration(seconds: 30);
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          if (_authToken != null) {
            options.headers['Authorization'] = 'Bearer $_authToken';
            developer.log('DEBUG: Adding Authorization header to request: ${options.path}', name: 'AriaApiClient');
          } else {
            options.headers.remove('Authorization');
            developer.log('DEBUG: No auth token, removing Authorization header from request: ${options.path}', name: 'AriaApiClient');
          }
          handler.next(options);
        },
        onError: (error, handler) {
          developer.log('ERROR in request: ${error.requestOptions.path}, status: ${error.response?.statusCode}, message: ${error.message}', name: 'AriaApiClient', error: error);
          handler.next(error);
        },
      ),
    );
    _dio.interceptors.add(
      LogInterceptor(requestBody: true, responseBody: true),
    );
  }

  void setAuthToken(String? token) {
    developer.log('DEBUG: Setting auth token: ${token != null ? 'token set (${token.length} chars)' : 'null'}', name: 'AriaApiClient');
    _authToken = token;
  }

  /// Register a new user
  Future<UserProfile> registerUser({
    required String email,
    required String username,
    required String password,
  }) async {
    try {
      final response = await _dio.post(
        '/auth/register',
        data: {
          'email': email,
          'username': username,
          'password': password,
        },
      );
      return UserProfile.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Login user and receive JWT token
  Future<AuthToken> login({
    required String username,
    required String password,
  }) async {
    try {
      final response = await _dio.post(
        '/auth/login',
        data: {
          'username': username,
          'password': password,
        },
      );
      final token =
          AuthToken.fromJson(response.data as Map<String, dynamic>);
      setAuthToken(token.accessToken);
      return token;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Fetch current authenticated user
  Future<UserProfile> getCurrentUser() async {
    try {
      final response = await _dio.get('/auth/me');
      developer.log('DEBUG: /auth/me response status: ${response.statusCode}', name: 'AriaApiClient');
      developer.log('DEBUG: /auth/me response data: ${response.data}', name: 'AriaApiClient');
      
      final data = response.data as Map<String, dynamic>;
      
      // Ensure isAdmin is present (default to false if missing)
      // Handle both camelCase and snake_case from backend
      if (!data.containsKey('isAdmin') && !data.containsKey('is_admin')) {
        developer.log('DEBUG: isAdmin not found, setting to false', name: 'AriaApiClient');
        data['isAdmin'] = false;
      } else if (data.containsKey('is_admin') && !data.containsKey('isAdmin')) {
        developer.log('DEBUG: Found is_admin, converting to isAdmin', name: 'AriaApiClient');
        data['isAdmin'] = data['is_admin'] as bool? ?? false;
      }
      
      developer.log('DEBUG: Parsing UserProfile from data: $data', name: 'AriaApiClient');
      final user = UserProfile.fromJson(data);
      developer.log('DEBUG: UserProfile created successfully: ${user.username}, isAdmin: ${user.isAdmin}', name: 'AriaApiClient');
      return user;
    } on DioException catch (e) {
      developer.log('ERROR in getCurrentUser: ${e.response?.data}', name: 'AriaApiClient', error: e);
      developer.log('ERROR status: ${e.response?.statusCode}', name: 'AriaApiClient');
      throw _handleError(e);
    } catch (e, stackTrace) {
      developer.log('ERROR parsing UserProfile: $e', name: 'AriaApiClient', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Restore latest saved session for current user
  Future<SessionDetails?> getLatestSession() async {
    try {
      final response = await _dio.get('/sessions/latest');
      return SessionDetails.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return null;
      }
      throw _handleError(e);
    }
  }

  /// Upload requirements from CSV/Excel file
  Future<UploadResponse> uploadRequirements({
    required Uint8List bytes,
    required String filename,
  }) async {
    try {
      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(
          bytes,
          filename: filename,
        ),
      });

      final response = await _dio.post('/requirements/upload', data: formData);

      // Manual parsing to avoid type errors in Flutter Web
      final data = response.data as Map<String, dynamic>;
      final requirementsList = data['requirements'] as List?;
      return UploadResponse(
        sessionId: data['sessionId'] as String,
        requirementsCount: data['requirementsCount'] as int,
        message: data['message'] as String,
        requirements: requirementsList?.map((req) => Requirement.fromJson(req as Map<String, dynamic>)).toList(),
      );
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

      // Manual parsing to avoid type errors in Flutter Web
      final data = response.data as Map<String, dynamic>;
      return CreateRequirementsResponse(
        sessionId: data['sessionId'] as String,
        requirementsCount: data['requirementsCount'] as int,
        message: data['message'] as String?,
      );
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

      // Простой парсинг ответа
      final data = response.data as Map<String, dynamic>;
      
      // Парсим базовые поля
      final responseSessionId = data['sessionId']?.toString() ?? '';
      final processingTimeMs = (data['processingTimeMs'] as num?)?.toInt() ?? 0;
      
      // Парсим metadata
      PrioritizationMetadata? metadata;
      if (data['metadata'] != null && data['metadata'] is Map) {
        final metaMap = data['metadata'] as Map<String, dynamic>;
        metadata = PrioritizationMetadata(
          totalRequirements: (metaMap['totalRequirements'] as num?)?.toInt(),
          averageScore: (metaMap['averageScore'] as num?)?.toDouble(),
          modelVersion: metaMap['modelVersion']?.toString(),
          weightsUsed: metaMap['weightsUsed'] != null
              ? Map<String, double>.from(
                  (metaMap['weightsUsed'] as Map).map(
                    (key, value) => MapEntry(
                      key.toString(),
                      (value as num).toDouble(),
                    ),
                  ),
                )
              : null,
        );
      }
      
      // Парсим требования
      final reqsList = data['prioritizedRequirements'] as List? ?? [];
      final List<PrioritizedRequirement> prioritizedRequirements = [];
      
      for (var i = 0; i < reqsList.length; i++) {
        final reqData = reqsList[i];
        if (reqData is Map) {
          final req = _parsePrioritizedRequirement(reqData as Map<String, dynamic>);
          prioritizedRequirements.add(req);
        }
      }
      
      return PrioritizationResponse(
        sessionId: responseSessionId,
        prioritizedRequirements: prioritizedRequirements,
        processingTimeMs: processingTimeMs,
        metadata: metadata,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    } catch (e) {
      throw Exception('Failed to parse prioritization response: $e');
    }
  }

  /// Get prioritization results
  Future<PrioritizationResponse> getPrioritization(String sessionId) async {
    try {
      final response = await _dio.get('/prioritization/$sessionId');
      final data = response.data as Map<String, dynamic>;
      
      // Используем тот же простой парсинг
      final responseSessionId = data['sessionId']?.toString() ?? '';
      final processingTimeMs = (data['processingTimeMs'] as num?)?.toInt() ?? 0;
      
      PrioritizationMetadata? metadata;
      if (data['metadata'] != null && data['metadata'] is Map) {
        final metaMap = data['metadata'] as Map<String, dynamic>;
        metadata = PrioritizationMetadata(
          totalRequirements: (metaMap['totalRequirements'] as num?)?.toInt(),
          averageScore: (metaMap['averageScore'] as num?)?.toDouble(),
          modelVersion: metaMap['modelVersion']?.toString(),
          weightsUsed: metaMap['weightsUsed'] != null
              ? Map<String, double>.from(
                  (metaMap['weightsUsed'] as Map).map(
                    (key, value) => MapEntry(
                      key.toString(),
                      (value as num).toDouble(),
                    ),
                  ),
                )
              : null,
        );
      }
      
      final reqsList = data['prioritizedRequirements'] as List? ?? [];
      final List<PrioritizedRequirement> prioritizedRequirements = [];
      
      for (var reqData in reqsList) {
        if (reqData is Map) {
          final req = _parsePrioritizedRequirement(reqData as Map<String, dynamic>);
          prioritizedRequirements.add(req);
        }
      }
      
      return PrioritizationResponse(
        sessionId: responseSessionId,
        prioritizedRequirements: prioritizedRequirements,
        processingTimeMs: processingTimeMs,
        metadata: metadata,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    } catch (e) {
      throw Exception('Failed to parse prioritization response: $e');
    }
  }
  
  /// Helper method to parse a PrioritizedRequirement from JSON
  PrioritizedRequirement _parsePrioritizedRequirement(Map<String, dynamic> reqData) {
    // Простая функция для парсинга double
    double? toDouble(dynamic value) {
      if (value == null) return null;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is num) return value.toDouble();
      return double.tryParse(value.toString());
    }
    
    // Простая функция для парсинга int
    int? toInt(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      if (value is double) return value.toInt();
      if (value is num) return value.toInt();
      return int.tryParse(value.toString());
    }
    
    // Парсим категорию
    RequirementCategory? parseCategory(String? categoryStr) {
      if (categoryStr == null || categoryStr.isEmpty) return null;
      final upper = categoryStr.toUpperCase();
      switch (upper) {
        case 'FEATURE':
          return RequirementCategory.feature;
        case 'ENHANCEMENT':
          return RequirementCategory.enhancement;
        case 'BUG_FIX':
        case 'BUGFIX':
          return RequirementCategory.bugFix;
        case 'TECHNICAL':
          return RequirementCategory.technical;
        case 'COMPLIANCE':
          return RequirementCategory.compliance;
        default:
          return null;
      }
    }
    
    return PrioritizedRequirement(
      id: reqData['id']?.toString() ?? '',
      title: reqData['title']?.toString() ?? '',
      description: reqData['description']?.toString() ?? '',
      businessValue: toDouble(reqData['businessValue']),
      cost: toDouble(reqData['cost']),
      risk: toDouble(reqData['risk']),
      urgency: toDouble(reqData['urgency']),
      stakeholderValue: toDouble(reqData['stakeholderValue']),
      category: parseCategory(reqData['category']?.toString()),
      priorityScore: toDouble(reqData['priorityScore']) ?? 0.0,
      rank: toInt(reqData['rank']) ?? 0,
      confidence: toDouble(reqData['confidence']),
      reasoning: reqData['reasoning']?.toString(),
    );
  }

  /// Request ChatGPT-powered analysis summary
  Future<String> analyzeWithChatGPT({
    required String sessionId,
    String? prompt,
  }) async {
    try {
      final response = await _dio.post(
        '/prioritization/chatgpt',
        data: {
          'sessionId': sessionId,
          if (prompt != null && prompt.trim().isNotEmpty) 'prompt': prompt,
        },
      );
      return response.data['summary'] as String;
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

  // ============================================================================
  // ADMIN ENDPOINTS
  // ============================================================================

  /// Get LLM configuration (admin only)
  Future<Map<String, dynamic>> getLLMConfig() async {
    try {
      final response = await _dio.get('/admin/llm-config');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Update LLM configuration (admin only)
  Future<Map<String, dynamic>> updateLLMConfig({
    required String apiKey,
    required String baseUrl,
    required String model,
  }) async {
    try {
      final response = await _dio.put(
        '/admin/llm-config',
        data: {
          'apiKey': apiKey,
          'baseUrl': baseUrl,
          'model': model,
        },
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Delete LLM configuration (admin only)
  Future<void> deleteLLMConfig() async {
    try {
      await _dio.delete('/admin/llm-config');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Exception _handleError(DioException error) {
    final data = error.response?.data;
    if (data != null) {
      if (data is Map<String, dynamic>) {
        try {
          // Manual parsing to avoid type errors in Flutter Web
          final apiError = ApiError(
            error: data['error']?.toString() ?? 'Error',
            message: data['message']?.toString() ?? data['detail']?.toString() ?? error.message ?? 'Unknown error',
            details: data['details'] as Map<String, dynamic>?,
          );
          return Exception('${apiError.error}: ${apiError.message}');
        } catch (_) {
          final message = data['detail'] ?? data['message'] ?? error.message;
          return Exception(message?.toString() ?? 'Unknown error');
        }
      } else if (data is String) {
        return Exception(data);
      }
    }
    return Exception(error.message);
  }
}
