import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'json_list_store.dart';

/// Base notifier for a list of [T] persisted through a [JsonListStore].
///
/// Handles the common async load-on-build and reload patterns shared by the
/// history notifiers.
abstract class JsonListNotifier<T> extends Notifier<List<T>> {
  /// The backing store for this list.
  JsonListStore<T> get store;

  @override
  List<T> build() {
    _load();
    return [];
  }

  Future<void> _load() async => state = await store.loadAll();

  /// Reloads the full list from the store.
  Future<void> reload() async => state = await store.loadAll();
}
