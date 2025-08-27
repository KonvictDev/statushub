import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import '../service/status_service.dart';

enum MediaType { all, images, videos }
enum SortOrder { recent, oldest }

class StatusState {
  final List<FileSystemEntity> allStatuses;
  final List<FileSystemEntity> savedStatuses;
  final MediaType selectedType;
  final SortOrder sortOrder;

  StatusState({
    required this.allStatuses,
    required this.savedStatuses,
    required this.selectedType,
    required this.sortOrder,
  });

  StatusState copyWith({
    List<FileSystemEntity>? allStatuses,
    List<FileSystemEntity>? savedStatuses,
    MediaType? selectedType,
    SortOrder? sortOrder,
  }) {
    return StatusState(
      allStatuses: allStatuses ?? this.allStatuses,
      savedStatuses: savedStatuses ?? this.savedStatuses,
      selectedType: selectedType ?? this.selectedType,
      sortOrder: sortOrder ?? this.sortOrder,
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
  ));

  Future<void> loadStatuses() async {
    final all = await StatusService.getStatuses();
    final saved = await StatusService.getSavedStatuses();
    state = state.copyWith(allStatuses: all, savedStatuses: saved);
  }

  void setMediaType(MediaType type) {
    state = state.copyWith(selectedType: type);
  }

  void setSortOrder(SortOrder order) {
    state = state.copyWith(sortOrder: order);
  }
}

final statusProvider = StateNotifierProvider<StatusNotifier, StatusState>((ref) {
  return StatusNotifier();
});

// Selector providers to get filtered/sorted lists
final filteredStatusProvider = Provider.family<List<FileSystemEntity>, bool>((ref, isSaved) {
  final state = ref.watch(statusProvider);
  final files = isSaved ? state.savedStatuses : state.allStatuses;
  final selectedType = state.selectedType;
  final sortOrder = state.sortOrder;

  final filtered = files.where((file) {
    final path = file.path.toLowerCase();
    final isImage = p.extension(path) == '.jpg' || p.extension(path) == '.jpeg' || p.extension(path) == '.png' || p.extension(path) == '.webp';
    final isVideo = p.extension(path) == '.mp4' || p.extension(path) == '.mov' || p.extension(path) == '.mkv' || p.extension(path) == '.avi' || p.extension(path) == '.3gp';

    switch (selectedType) {
      case MediaType.images:
        return isImage;
      case MediaType.videos:
        return isVideo;
      case MediaType.all:
      default:
        return isImage || isVideo;
    }
  }).toList();

  filtered.sort((a, b) {
    final aTime = a.statSync().modified;
    final bTime = b.statSync().modified;
    return sortOrder == SortOrder.recent ? bTime.compareTo(aTime) : aTime.compareTo(bTime);
  });

  return filtered;
});