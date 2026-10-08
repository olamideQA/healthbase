import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/errors/failures.dart';
import '../../data/measurement_repository.dart';
import '../../domain/models/measurement.dart';

final measurementControllerProvider =
    StateNotifierProvider<MeasurementController, AsyncValue<Measurement?>>((ref) {
  final repo = ref.watch(measurementRepositoryProvider);
  return MeasurementController(repo);
});

class MeasurementController extends StateNotifier<AsyncValue<Measurement?>> {
  MeasurementController(this._repo) : super(const AsyncValue.data(null));

  final MeasurementRepository _repo;

  /// Record a new measurement locally with sync queuing.
  Future<bool> recordMeasurement(Measurement measurement) async {
    state = const AsyncValue.loading();
    try {
      final saved = await _repo.createMeasurement(measurement);
      state = AsyncValue.data(saved);
      return true;
    } on Failure catch (f, st) {
      state = AsyncValue.error(f, st);
      return false;
    } catch (e, st) {
      state = AsyncValue.error(UnexpectedFailure(cause: e), st);
      return false;
    }
  }

  /// Delete a measurement by ID.
  Future<bool> deleteMeasurement(String id, String profileId) async {
    state = const AsyncValue.loading();
    try {
      await _repo.deleteMeasurement(id, profileId);
      state = const AsyncValue.data(null);
      return true;
    } on Failure catch (f, st) {
      state = AsyncValue.error(f, st);
      return false;
    } catch (e, st) {
      state = AsyncValue.error(UnexpectedFailure(cause: e), st);
      return false;
    }
  }

  /// Trigger sync.
  Future<void> sync(String profileId) async {
    try {
      await _repo.syncProfile(profileId);
    } catch (e) {
      // Background sync failures shouldn't block UI state
    }
  }
}
