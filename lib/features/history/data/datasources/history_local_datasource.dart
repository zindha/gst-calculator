import '../../../../core/utils/json_list_store.dart';
import '../models/history_entry.dart';

/// SharedPreferences-backed store for calculation history.
final historyStore = JsonListStore<HistoryEntry>(
  key: 'calculation_history',
  fromJson: HistoryEntry.fromJson,
  toJson: (e) => e.toJson(),
  idOf: (e) => e.id,
  sortBy: (e) => e.timestamp,
);
