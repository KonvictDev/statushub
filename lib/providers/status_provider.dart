import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import '../service/status_service.dart'; //

enum MediaType { all, images, videos }
enum SortOrder { recent, oldest }

// Lightweight model to hold file and pre-calculated metadata
class StatusModel {
  final FileSystemEntity file;
  final DateTime updatedAt;
  StatusModel({required this.file, required this.updatedAt});
}

class StatusState {
  final List<StatusModel> allStatuses;
  final List<StatusModel> savedStatuses;
  final MediaType selectedType;
  final SortOrder sortOrder;
  final WhatsAppType currentApp;

  StatusState({
    required this.allStatuses,
    required this.savedStatuses,
    required this.selectedType,
    required this.sortOrder,
    required this.currentApp,
  });

  StatusState copyWith({
    List<StatusModel>? allStatuses,
    List<StatusModel>? savedStatuses,
    MediaType? selectedType,
    SortOrder? sortOrder,
    WhatsAppType? currentApp,
  }) {
    return StatusState(
      allStatuses: allStatuses ?? this.allStatuses,
      savedStatuses: savedStatuses ?? this.savedStatuses,
      selectedType: selectedType ?? this.selectedType,
      sortOrder: sortOrder ?? this.sortOrder,
      currentApp: currentApp ?? this.currentApp,
    );
  }
}

class StatusNotifier extends StateNotifier<StatusState> {
  StatusNotifier()
      : super(StatusState(
    allStatuses: [],
    savedStatuses: [],
    selectedType: MediaType.all,
    sortOrder: SortOrder.recent,
    currentApp: WhatsAppType.whatsapp,
  ));

  Future<void> loadStatuses() async {
    // Parallel fetching of raw entities
    final rawAll = await StatusService.getStatuses(state.currentApp);
    final rawSaved = await StatusService.getSavedStatuses();

    // PERFORMANCE: Pre-calculate metadata in parallel to avoid UI jank
    final allModels = await _convertToModels(rawAll);
    final savedModels = await _convertToModels(rawSaved);

    if (mounted) {
      state = state.copyWith(allStatuses: allModels, savedStatuses: savedModels);
    }
  }

  Future<List<StatusModel>> _convertToModels(List<FileSystemEntity> files) async {
    return Future.wait(files.map((f) async {
      try {
        final stat = await f.stat(); // I/O happens once here
        return StatusModel(file: f, updatedAt: stat.modified);
      } catch (e) {
        return StatusModel(file: f, updatedAt: DateTime(1970));
      }
    }));
  }

  Future<void> switchApp(WhatsAppType type) async {
    state = state.copyWith(currentApp: type);
    await loadStatuses();
  }

  void setMediaType(MediaType type) => state = state.copyWith(selectedType: type);
  void setSortOrder(SortOrder order) => state = state.copyWith(sortOrder: order);
}

final statusProvider = StateNotifierProvider<StatusNotifier, StatusState>((ref) => StatusNotifier());

final filteredStatusProvider = Provider.family<List<FileSystemEntity>, bool>((ref, isSaved) {
  final state = ref.watch(statusProvider);
  final models = isSaved ? state.savedStatuses : state.allStatuses;

  // Filtering and Sorting now use lightning-fast in-memory metadata
  final filtered = models.where((model) {
    final ext = p.extension(model.file.path).toLowerCase();
    final isImage = ['.jpg', '.jpeg', '.png', '.webp'].contains(ext);
    final isVideo = ['.mp4', '.mov', '.mkv', '.avi', '.gif', '.3gp'].contains(ext);

    if (state.selectedType == MediaType.images) return isImage;
    if (state.selectedType == MediaType.videos) return isVideo;
    return isImage || isVideo;
  }).toList();

  filtered.sort((a, b) => state.sortOrder == SortOrder.recent
      ? b.updatedAt.compareTo(a.updatedAt)
      : a.updatedAt.compareTo(b.updatedAt));

  return filtered.map((m) => m.file).toList();
});