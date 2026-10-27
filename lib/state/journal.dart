import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/places.dart';
import '../models/place.dart';

/// Saved places, kept in the order they were collected.
class JournalController extends ChangeNotifier {
  static const _storageKey = 'elsewhere.journal.v1';

  final List<String> _saved = [];
  bool _loaded = false;

  List<String> get ids => List.unmodifiable(_saved);
  bool get isEmpty => _saved.isEmpty;
  bool get isLoaded => _loaded;
  int get count => _saved.length;

  List<Place> get savedPlaces {
    final result = <Place>[];
    for (final id in _saved) {
      for (final place in places) {
        if (place.id == id) {
          result.add(place);
          break;
        }
      }
    }
    return List.unmodifiable(result);
  }

  bool isSaved(String id) => _saved.contains(id);

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getStringList(_storageKey) ?? const [];
    _saved
      ..clear()
      ..addAll(stored.where((id) => places.any((p) => p.id == id)));

    // A demo-only deep link lets the web build open with a few places kept.
    if (kIsWeb && Uri.base.queryParameters['saved'] == '1' && _saved.isEmpty) {
      _saved.addAll(['lofoten', 'kyoto', 'merzouga']);
    }
    _loaded = true;
    notifyListeners();
  }

  Future<void> toggle(String id) async {
    if (_saved.remove(id)) {
      notifyListeners();
    } else {
      _saved.insert(0, id);
      notifyListeners();
    }
    await _persist();
  }

  Future<void> remove(String id) async {
    if (_saved.remove(id)) {
      notifyListeners();
      await _persist();
    }
  }

  Future<void> clear() async {
    if (_saved.isEmpty) return;
    _saved.clear();
    notifyListeners();
    await _persist();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_storageKey, _saved);
  }
}
