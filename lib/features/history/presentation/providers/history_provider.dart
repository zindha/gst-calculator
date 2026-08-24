import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/json_list_notifier.dart';
import '../../../../core/utils/json_list_store.dart';
import '../../data/datasources/history_local_datasource.dart';
import '../../data/models/history_entry.dart';

/// Provider for the calculation history list.
final historyProvider = NotifierProvider<HistoryNotifier, List<HistoryEntry>>(
  HistoryNotifier.new,
);

class HistoryNotifier extends JsonListNotifier<HistoryEntry> {
  @override
  JsonListStore<HistoryEntry> get store => historyStore;

  /// Serialises overlapping store writes. `JsonListStore.save` is a
  /// read-modify-write (load all, insert, persist), so two saves racing each
  /// other can lose an entry. The debounced auto-save reduces write volume,
  /// and this queue makes the remaining writes strictly ordered.
  Future<void> _writeQueue = Future.value();

  /// Saves a new [entry] to history and updates state.
  Future<void> addEntry(HistoryEntry entry) async {
    state = [entry, ...state];
    // Chain this write behind any in-flight write. Errors in one write are
    // swallowed so the queue never stalls; the entry is still in `state` and
    // a later `reload()` re-reads the store.
    _writeQueue = _writeQueue.then((_) => store.save(entry)).catchError((_) {});
    await _writeQueue;
  }

  /// Deletes the entry with the given [id].
  Future<void> deleteEntry(String id) async {
    // Serialize with any in-flight write (same queue as [addEntry]) so a
    // queued save can't resurrect an entry this delete just removed.
    _writeQueue = _writeQueue.then((_) => store.delete(id)).catchError((_) {});
    await _writeQueue;
    state = state.where((e) => e.id != id).toList();
  }

  /// Clears all history entries.
  Future<void> clearAll() async {
    // Same queue discipline as [deleteEntry]: a pending auto-save write must
    // complete (or fail) before the clear, or it could re-persist entries.
    _writeQueue = _writeQueue.then((_) => store.clear()).catchError((_) {});
    await _writeQueue;
    state = [];
  }
}
