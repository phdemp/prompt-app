import 'package:flutter/foundation.dart';
import '../models/prompt_model.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';

class PromptProvider extends ChangeNotifier {
  List<PromptModel> prompts = [];
  int currentPage = 1;
  int totalPages = 1;
  bool isLoadingHistory = false;
  bool isLoadingMore = false;
  String? error;

  final ApiService _apiService = ApiService(StorageService());

  Future<void> fetchHistory({bool refresh = false}) async {
    if (isLoadingHistory) return;

    if (refresh) {
      currentPage = 1;
      totalPages = 1;
      prompts = [];
    }

    isLoadingHistory = true;
    error = null;
    notifyListeners();

    try {
      final data = await _apiService.getHistory(page: currentPage, limit: 10);
      final items = (data['prompts'] ?? data['data'] ?? []) as List;
      final pagination = data['pagination'] as Map<String, dynamic>? ?? {};

      totalPages = (pagination['totalPages'] ?? pagination['total_pages'] ?? 1) as int;
      prompts = items.map((e) => PromptModel.fromJson(e as Map<String, dynamic>)).toList();
      error = null;
    } catch (e) {
      error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      isLoadingHistory = false;
      notifyListeners();
    }
  }

  Future<void> loadMoreHistory() async {
    if (isLoadingMore || currentPage >= totalPages) return;

    isLoadingMore = true;
    notifyListeners();

    try {
      currentPage++;
      final data = await _apiService.getHistory(page: currentPage, limit: 10);
      final items = (data['prompts'] ?? data['data'] ?? []) as List;
      final pagination = data['pagination'] as Map<String, dynamic>? ?? {};

      totalPages = (pagination['totalPages'] ?? pagination['total_pages'] ?? 1) as int;
      prompts.addAll(items.map((e) => PromptModel.fromJson(e as Map<String, dynamic>)));
    } catch (e) {
      currentPage--; // Rollback page increment on failure
      error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      isLoadingMore = false;
      notifyListeners();
    }
  }

  Future<void> deletePrompt(String id) async {
    await _apiService.deletePrompt(id);
    prompts.removeWhere((p) => p.id == id);
    notifyListeners();
  }

  /// Prepends a newly optimized result to the history list.
  void prependResult(PromptModel prompt) {
    prompts.insert(0, prompt);
    notifyListeners();
  }

  void clear() {
    prompts = [];
    currentPage = 1;
    totalPages = 1;
    error = null;
    notifyListeners();
  }
}
