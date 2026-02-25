import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/optimization_result.dart';
import '../models/prompt_model.dart';
import '../models/usage_stats.dart';
import '../utils/constants.dart';
import 'storage_service.dart';

class ApiException implements Exception {
  final String message;
  final String? code;

  ApiException({required this.message, this.code});

  @override
  String toString() => message;
}

class ApiService {
  final StorageService _storageService;

  ApiService(this._storageService);

  Future<Map<String, dynamic>> _makeRequest(
    String method,
    String path, {
    Map<String, dynamic>? body,
    bool requiresAuth = true,
  }) async {
    try {
      final headers = <String, String>{
        'Content-Type': 'application/json',
      };

      if (requiresAuth) {
        final token = await _storageService.getToken();
        if (token != null) {
          headers['Authorization'] = 'Bearer $token';
        }
      }

      final uri = Uri.parse('$kApiBaseUrl$path');
      http.Response response;

      switch (method.toUpperCase()) {
        case 'GET':
          response = await http.get(uri, headers: headers);
          break;
        case 'POST':
          response = await http.post(
            uri,
            headers: headers,
            body: body != null ? jsonEncode(body) : null,
          );
          break;
        case 'DELETE':
          response = await http.delete(uri, headers: headers);
          break;
        default:
          throw ApiException(message: 'Unsupported HTTP method: $method');
      }

      if (response.statusCode == 401) {
        throw ApiException(message: 'Unauthorized. Please sign in again.', code: 'unauthorized');
      }

      if (response.statusCode == 429) {
        throw ApiException(message: 'Too many requests. Please slow down.', code: 'rate_limited');
      }

      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (response.body.isEmpty) return {};
        return jsonDecode(response.body) as Map<String, dynamic>;
      }

      // 4xx/5xx errors
      Map<String, dynamic> errorBody = {};
      try {
        errorBody = jsonDecode(response.body) as Map<String, dynamic>;
      } catch (_) {}
      throw ApiException(
        message: errorBody['message']?.toString() ?? 'Server error (${response.statusCode})',
      );
    } on SocketException {
      throw ApiException(
        message: 'No internet connection. Please check your network.',
        code: 'network_error',
      );
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        message: 'An unexpected error occurred: $e',
        code: 'network_error',
      );
    }
  }

  Future<OptimizationResult> optimizePrompt(String rawPrompt, String type) async {
    final data = await _makeRequest(
      'POST',
      '/api/optimize',
      body: {'rawPrompt': rawPrompt, 'optimizationType': type},
    );
    return OptimizationResult.fromJson(data);
  }

  Future<Map<String, dynamic>> getHistory({int page = 1, int limit = 10}) async {
    final data = await _makeRequest('GET', '/api/history?page=$page&limit=$limit');
    return data;
  }

  Future<PromptModel> getPromptById(String id) async {
    final data = await _makeRequest('GET', '/api/history/$id');
    return PromptModel.fromJson(data);
  }

  Future<void> deletePrompt(String id) async {
    await _makeRequest('DELETE', '/api/history/$id');
  }

  Future<UsageStats> getUsageStats() async {
    final data = await _makeRequest('GET', '/api/usage');
    return UsageStats.fromJson(data);
  }

  Future<bool> healthCheck() async {
    try {
      final response = await http.get(Uri.parse('$kApiBaseUrl/health'));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
