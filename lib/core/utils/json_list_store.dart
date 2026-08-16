import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Generic SharedPreferences-backed store for a JSON-encoded list of [T].
///
/// Replaces the load/save/delete/persist logic that each feature datasource
/// previously re-implemented by hand.
class JsonListStore<T> {
  JsonListStore({
    required this.key,
    required this.fromJson,
    required this.toJson,
    this.idOf,
    this.sortBy,
    this.prependNew = true,
  });

  /// SharedPreferences key under which the JSON list is stored.
  final String key;

  /// Builds a [T] from its JSON map.
  final T Function(Map<String, dynamic> json) fromJson;

  /// Serialises a [T] to its JSON map.
  final Map<String, dynamic> Function(T item) toJson;

  /// Returns the stable id of an item, used for upsert and delete.
  /// When null, [save] always prepends/appends and [delete] removes nothing.
  final String Function(T item)? idOf;

  /// When provided, items are sorted newest-first by this key after load.
  final int Function(T item)? sortBy;

  /// Whether [save] inserts new items at the front of the list (newest first)
  /// rather than appending them at the end.
  final bool prependNew;

  /// Loads all stored items, sorted newest-first when [sortBy] is set.
  Future<List<T>> loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(key);
    if (json == null || json.isEmpty) return [];
    try {
      final items =
          (jsonDecode(json) as List)
              .map((e) => fromJson(e as Map<String, dynamic>))
              .toList();
      final sorter = sortBy;
      if (sorter != null) {
        items.sort((a, b) => sorter(b).compareTo(sorter(a)));
      }
      return items;
    } catch (_) {
      return [];
    }
  }

  /// Inserts [item] at the front (or end when [prependNew] is false),
  /// or replaces the existing item with the same id.
  Future<void> save(T item) async {
    final items = await loadAll();
    final id = idOf?.call(item);
    if (id != null) {
      final index = items.indexWhere((e) => idOf!(e) == id);
      if (index >= 0) {
        items[index] = item;
      } else {
        items.insert(prependNew ? 0 : items.length, item);
      }
    } else {
      items.insert(prependNew ? 0 : items.length, item);
    }
    await persist(items);
  }

  /// Removes the item with the given [id].
  Future<void> delete(String id) async {
    final items = await loadAll();
    items.removeWhere((e) => idOf?.call(e) == id);
    await persist(items);
  }

  /// Removes all items.
  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(key);
  }

  /// Replaces the full persisted list.
  Future<void> persist(List<T> items) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, jsonEncode(items.map(toJson).toList()));
  }
}
