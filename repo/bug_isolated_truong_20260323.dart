enum BugSeverity {
  low,
  medium,
  high,
  critical,
}

enum BugStatus {
  open,
  inProgress,
  resolved,
  closed,
}

class BugComment {
  final String author;
  final String message;
  final DateTime createdAt;

  const BugComment({
    required this.author,
    required this.message,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'author': author,
      'message': message,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

class BugIsolatedTruong20260323 {
  final String id;
  final String title;
  final String description;
  final String reporter;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final BugSeverity severity;
  final BugStatus status;
  final List<String> labels;
  final List<BugComment> comments;

  const BugIsolatedTruong20260323({
    required this.id,
    required this.title,
    required this.description,
    required this.reporter,
    required this.createdAt,
    this.updatedAt,
    this.severity = BugSeverity.medium,
    this.status = BugStatus.open,
    this.labels = const <String>[],
    this.comments = const <BugComment>[],
  });

  static BugIsolatedTruong20260323 sample() {
    return BugIsolatedTruong20260323(
      id: 'BUG-ISO-20260323',
      title: 'Isolated bug note',
      description: 'Standalone repo file, not used by app runtime.',
      reporter: 'truong',
      createdAt: DateTime(2026, 3, 23),
      severity: BugSeverity.low,
      status: BugStatus.open,
      labels: const ['repo-only', 'isolated', 'no-runtime-impact'],
      comments: const [
        BugComment(
          author: 'system',
          message: 'Created as an isolated tracking sample.',
          createdAt: DateTime(2026, 3, 23),
        ),
      ],
    );
  }

  BugIsolatedTruong20260323 copyWith({
    String? id,
    String? title,
    String? description,
    String? reporter,
    DateTime? createdAt,
    DateTime? updatedAt,
    BugSeverity? severity,
    BugStatus? status,
    List<String>? labels,
    List<BugComment>? comments,
  }) {
    return BugIsolatedTruong20260323(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      reporter: reporter ?? this.reporter,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      severity: severity ?? this.severity,
      status: status ?? this.status,
      labels: labels ?? this.labels,
      comments: comments ?? this.comments,
    );
  }

  BugIsolatedTruong20260323 addLabel(String label) {
    final normalized = BugTextTools.normalize(label);
    if (normalized.isEmpty || labels.contains(normalized)) return this;
    return copyWith(
      labels: [...labels, normalized],
      updatedAt: DateTime.now(),
    );
  }

  BugIsolatedTruong20260323 addComment(BugComment comment) {
    return copyWith(
      comments: [...comments, comment],
      updatedAt: DateTime.now(),
    );
  }

  BugIsolatedTruong20260323 markResolved() {
    return copyWith(status: BugStatus.resolved, updatedAt: DateTime.now());
  }

  bool get isOpenLike =>
      status == BugStatus.open || status == BugStatus.inProgress;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'reporter': reporter,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'severity': severity.name,
      'status': status.name,
      'labels': labels,
      'comments': comments.map((value) => value.toMap()).toList(),
      'priorityScore': BugMathTools.priorityScore(severity, isOpenLike),
    };
  }

  @override
  String toString() {
    return 'BugIsolatedTruong20260323(id: $id, status: ${status.name}, severity: ${severity.name})';
  }
}

class BugTextTools {
  static String normalize(String value) {
    return value.trim().replaceAll(RegExp(r'\s+'), ' ');
  }

  static bool isMeaningful(String value, {int minLength = 3}) {
    return normalize(value).length >= minLength;
  }

  static String slug(String value) {
    final normalized = normalize(value).toLowerCase();
    final safe = normalized.replaceAll(RegExp(r'[^a-z0-9\s-]'), '');
    return safe.replaceAll(RegExp(r'[\s-]+'), '-');
  }
}

class BugMathTools {
  static int priorityScore(BugSeverity severity, bool isOpen) {
    final base = switch (severity) {
      BugSeverity.low => 10,
      BugSeverity.medium => 30,
      BugSeverity.high => 60,
      BugSeverity.critical => 90,
    };
    return isOpen ? base + 10 : base;
  }

  static double completionRate(List<BugIsolatedTruong20260323> bugs) {
    if (bugs.isEmpty) return 0;
    final closedCount = bugs
        .where((bug) =>
            bug.status == BugStatus.resolved || bug.status == BugStatus.closed)
        .length;
    return (closedCount / bugs.length) * 100;
  }
}

class BugRepositoryStandalone {
  final List<BugIsolatedTruong20260323> _items =
      <BugIsolatedTruong20260323>[];

  void add(BugIsolatedTruong20260323 bug) {
    _items.add(bug);
  }

  List<BugIsolatedTruong20260323> all() {
    return List<BugIsolatedTruong20260323>.unmodifiable(_items);
  }

  BugIsolatedTruong20260323? findById(String id) {
    for (final bug in _items) {
      if (bug.id == id) return bug;
    }
    return null;
  }

  List<BugIsolatedTruong20260323> filterOpen() {
    return _items.where((bug) => bug.isOpenLike).toList(growable: false);
  }

  Map<String, dynamic> summary() {
    return {
      'total': _items.length,
      'open': _items.where((bug) => bug.isOpenLike).length,
      'completionRate': BugMathTools.completionRate(_items),
    };
  }
}

class BugStandaloneDemoRunner {
  static Map<String, dynamic> run() {
    final repository = BugRepositoryStandalone();
    final base = BugIsolatedTruong20260323.sample();

    final inProgress = base.copyWith(
      status: BugStatus.inProgress,
      updatedAt: DateTime.now(),
    );

    final resolved = inProgress
        .addComment(
          BugComment(
            author: 'developer',
            message: 'Fix implemented locally.',
            createdAt: DateTime.now(),
          ),
        )
        .markResolved();

    repository.add(base);
    repository.add(inProgress);
    repository.add(resolved);

    return {
      'firstSlug': BugTextTools.slug(base.title),
      'firstPriority': BugMathTools.priorityScore(base.severity, base.isOpenLike),
      'summary': repository.summary(),
      'items': repository.all().map((item) => item.toMap()).toList(),
    };
  }
}
