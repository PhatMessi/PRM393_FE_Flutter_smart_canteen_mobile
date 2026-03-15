import 'package:flutter/foundation.dart';

import '../models/menu_item.dart';
import '../services/favorites_service.dart';

class FavoritesProvider extends ChangeNotifier {
  final FavoritesService _favoritesService;
  final Map<int, MenuItem> _itemsById = <int, MenuItem>{};

  String? _token;
  bool _isLoaded = false;
  bool _isLoading = false;

  FavoritesProvider({FavoritesService? favoritesService})
    : _favoritesService = favoritesService ?? FavoritesService();

  bool get isLoaded => _isLoaded;
  bool get isLoading => _isLoading;

  List<MenuItem> get items => _itemsById.values.toList(growable: false);

  bool isFavorite(int itemId) => _itemsById.containsKey(itemId);

  Future<void> updateToken(String? token) async {
    if (_token == token) return;

    _token = token;
    _itemsById.clear();
    _isLoaded = false;
    notifyListeners();

    if (_token == null || _token!.isEmpty) {
      _isLoaded = true;
      notifyListeners();
      return;
    }

    await refresh();
  }

  Future<void> refresh() async {
    final token = _token;
    if (token == null || token.isEmpty) {
      _itemsById.clear();
      _isLoaded = true;
      notifyListeners();
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      final list = await _favoritesService.getMyFavorites(token);
      _itemsById
        ..clear()
        ..addEntries(list.map((item) => MapEntry(item.itemId, item)));
    } finally {
      _isLoading = false;
      _isLoaded = true;
      notifyListeners();
    }
  }

  Future<void> add(MenuItem item) async {
    final token = _token;
    if (token == null || token.isEmpty) return;
    if (_itemsById.containsKey(item.itemId)) return;

    await _favoritesService.addFavorite(token, item.itemId);
    _itemsById[item.itemId] = item;
    notifyListeners();
  }

  Future<void> remove(int itemId) async {
    final token = _token;
    if (token == null || token.isEmpty) return;
    if (!_itemsById.containsKey(itemId)) return;

    await _favoritesService.removeFavorite(token, itemId);
    _itemsById.remove(itemId);
    notifyListeners();
  }

  Future<void> toggle(MenuItem item) async {
    if (isFavorite(item.itemId)) {
      await remove(item.itemId);
    } else {
      await add(item);
    }
  }
}
