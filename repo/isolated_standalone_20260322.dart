class IsolatedStandalone20260322 {
  final String id;
  final String owner;
  final DateTime createdAt;
  final List<String> tags;

  IsolatedStandalone20260322({
    required this.id,
    required this.owner,
    DateTime? createdAt,
    List<String>? tags,
  }) : createdAt = createdAt ?? DateTime.now(),
       tags = List.unmodifiable(tags ?? const <String>[]);

  static IsolatedStandalone20260322 sample() {
    return IsolatedStandalone20260322(
      id: 'ISO-20260322',
      owner: 'local-user',
      tags: const ['standalone', 'safe', 'repo-only'],
    );
  }

  String marker() => 'isolated';

  bool hasTag(String tag) {
    for (final value in tags) {
      if (value.toLowerCase() == tag.toLowerCase()) return true;
    }
    return false;
  }

  IsolatedStandalone20260322 withAdditionalTag(String tag) {
    if (hasTag(tag)) return this;
    return IsolatedStandalone20260322(
      id: id,
      owner: owner,
      createdAt: createdAt,
      tags: [...tags, tag],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'owner': owner,
      'createdAt': createdAt.toIso8601String(),
      'tags': tags,
      'marker': marker(),
    };
  }

  @override
  String toString() {
    return 'IsolatedStandalone20260322(id: $id, owner: $owner, tags: $tags)';
  }
}

class IsolatedTextToolkit {
  static String normalizeWhitespace(String input) {
    final parts = input.trim().split(RegExp(r'\s+'));
    return parts.join(' ');
  }

  static String toSlug(String input) {
    final normalized = normalizeWhitespace(input).toLowerCase();
    final onlyValid = normalized.replaceAll(RegExp(r'[^a-z0-9\s-]'), '');
    return onlyValid.replaceAll(RegExp(r'[\s-]+'), '-');
  }

  static String reverse(String input) {
    return input.split('').reversed.join();
  }
}

class IsolatedNumberToolkit {
  static int clampInt(int value, int min, int max) {
    if (value < min) return min;
    if (value > max) return max;
    return value;
  }

  static int sum(Iterable<int> values) {
    var total = 0;
    for (final value in values) {
      total += value;
    }
    return total;
  }

  static double average(Iterable<int> values) {
    final list = values.toList();
    if (list.isEmpty) return 0;
    return sum(list) / list.length;
  }
}

class IsolatedKeyValueStore {
  final Map<String, String> _storage = <String, String>{};

  void put(String key, String value) {
    _storage[key] = value;
  }

  String? get(String key) => _storage[key];

  bool contains(String key) => _storage.containsKey(key);

  String remove(String key) => _storage.remove(key) ?? '';

  void clear() => _storage.clear();

  int get length => _storage.length;

  List<String> keys() => _storage.keys.toList(growable: false);
}

class IsolatedDemoRunner {
  static Map<String, dynamic> run() {
    final base = IsolatedStandalone20260322.sample();
    final model = base.withAdditionalTag('extended');

    final textSource = '  Repo   only    Dart  file  ';
    final normalized = IsolatedTextToolkit.normalizeWhitespace(textSource);
    final slug = IsolatedTextToolkit.toSlug(textSource);

    final numbers = <int>[10, 15, 20, 25];
    final sum = IsolatedNumberToolkit.sum(numbers);
    final avg = IsolatedNumberToolkit.average(numbers);

    final store = IsolatedKeyValueStore()
      ..put('normalized', normalized)
      ..put('slug', slug)
      ..put('sum', '$sum')
      ..put('avg', avg.toStringAsFixed(2));

    return {
      'model': model.toMap(),
      'normalized': normalized,
      'slug': slug,
      'reverseSlug': IsolatedTextToolkit.reverse(slug),
      'sum': sum,
      'average': avg,
      'storeKeys': store.keys(),
      'storeLength': store.length,
    };
  }
}
