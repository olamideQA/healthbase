import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/timeline_repository.dart';
import '../../domain/models/timeline_entry.dart';

class TimelineState {
  const TimelineState({
    this.records = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = false,
    this.pageIndex = 0,
    this.nextCursor,
    this.dateFilter = TimelineDateFilter.allTime,
    this.metricFilter = TimelineMetricFilter.all,
    this.customRange,
    this.errorMessage,
  });

  final List<TimelineDayRecord> records;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final int pageIndex;
  final DateTime? nextCursor;
  final TimelineDateFilter dateFilter;
  final TimelineMetricFilter metricFilter;
  final DateTimeRange? customRange;
  final String? errorMessage;

  TimelineState copyWith({
    List<TimelineDayRecord>? records,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    int? pageIndex,
    DateTime? nextCursor,
    bool clearCursor = false,
    TimelineDateFilter? dateFilter,
    TimelineMetricFilter? metricFilter,
    DateTimeRange? customRange,
    String? errorMessage,
    bool clearError = false,
  }) {
    return TimelineState(
      records: records ?? this.records,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      pageIndex: pageIndex ?? this.pageIndex,
      nextCursor: clearCursor ? null : (nextCursor ?? this.nextCursor),
      dateFilter: dateFilter ?? this.dateFilter,
      metricFilter: metricFilter ?? this.metricFilter,
      customRange: customRange ?? this.customRange,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

final timelineControllerProvider =
    StateNotifierProvider.family<TimelineController, TimelineState, String>(
  (ref, profileId) {
    final repo = ref.watch(timelineRepositoryProvider);
    return TimelineController(repo: repo, profileId: profileId);
  },
);

class TimelineController extends StateNotifier<TimelineState> {
  TimelineController({
    required this.repo,
    required this.profileId,
  }) : super(const TimelineState()) {
    loadInitial();
  }

  final TimelineRepository repo;
  final String profileId;
  static const int pageSize = 15;

  /// Load initial page of records based on current filters.
  Future<void> loadInitial() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final pageResult = await repo.getTimelinePage(
        profileId: profileId,
        pageIndex: 0,
        pageSize: pageSize,
        dateFilter: state.dateFilter,
        metricFilter: state.metricFilter,
        customRange: state.customRange,
      );

      state = state.copyWith(
        records: pageResult.records,
        isLoading: false,
        hasMore: pageResult.hasMore,
        pageIndex: 0,
        nextCursor: pageResult.nextCursor,
        clearCursor: pageResult.nextCursor == null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  /// Load subsequent page for infinite scrolling/pagination.
  Future<void> loadMore() async {
    if (state.isLoading || state.isLoadingMore || !state.hasMore) return;

    state = state.copyWith(isLoadingMore: true);
    try {
      final nextPage = state.pageIndex + 1;
      final pageResult = await repo.getTimelinePage(
        profileId: profileId,
        pageIndex: nextPage,
        pageSize: pageSize,
        beforeCursor: state.nextCursor,
        dateFilter: state.dateFilter,
        metricFilter: state.metricFilter,
        customRange: state.customRange,
      );

      // Append new days, avoiding duplicate day keys
      final existingDates = state.records.map((r) => r.date).toSet();
      final newRecords = pageResult.records
          .where((r) => !existingDates.contains(r.date))
          .toList();

      state = state.copyWith(
        records: [...state.records, ...newRecords],
        isLoadingMore: false,
        hasMore: pageResult.hasMore,
        pageIndex: nextPage,
        nextCursor: pageResult.nextCursor,
        clearCursor: pageResult.nextCursor == null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoadingMore: false,
        errorMessage: e.toString(),
      );
    }
  }

  /// Change active date filter (e.g. 7D, 30D, 90D, All, Custom).
  Future<void> setDateFilter(TimelineDateFilter filter, [DateTimeRange? range]) async {
    if (state.dateFilter == filter && state.customRange == range) return;
    state = state.copyWith(
      dateFilter: filter,
      customRange: range,
    );
    await loadInitial();
  }

  /// Change active metric filter (e.g. HR, BP, Glucose, Symptoms, etc.).
  Future<void> setMetricFilter(TimelineMetricFilter filter) async {
    if (state.metricFilter == filter) return;
    state = state.copyWith(metricFilter: filter);
    await loadInitial();
  }

  /// Pull-to-refresh timeline.
  Future<void> refresh() async {
    await loadInitial();
  }

  /// Trigger offline sync push and pull.
  Future<void> triggerSync() async {
    try {
      await repo.syncEngine.syncProfile(profileId);
      await refresh();
    } catch (_) {
      // Sync errors handled by sync engine
    }
  }
}
