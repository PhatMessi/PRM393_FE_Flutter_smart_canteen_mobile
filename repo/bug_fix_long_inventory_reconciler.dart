/// Standalone long bug-fix module: Inventory Reconciler
///
/// This file fixes common inventory consistency bugs in legacy scripts:
/// - negative stock after concurrent updates
/// - duplicate event replay causing double counting
/// - unordered event streams producing wrong balances
/// - inconsistent unit conversion
/// - invalid events crashing the reconciliation run
///
/// No external imports and no dependency on project code outside `repo/`.

class InventoryEvent {
  final String eventId;
  final String sku;
  final String action; // IN, OUT, ADJUST, RESERVE, RELEASE
  final double quantity;
  final String unit; // piece, box, carton
  final DateTime timestamp;
  final Map<String, String> metadata;

  const InventoryEvent({
    required this.eventId,
    required this.sku,
    required this.action,
    required this.quantity,
    required this.unit,
    required this.timestamp,
    required this.metadata,
  });

  InventoryEvent copyWith({
    String? eventId,
    String? sku,
    String? action,
    double? quantity,
    String? unit,
    DateTime? timestamp,
    Map<String, String>? metadata,
  }) {
    return InventoryEvent(
      eventId: eventId ?? this.eventId,
      sku: sku ?? this.sku,
      action: action ?? this.action,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      timestamp: timestamp ?? this.timestamp,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  String toString() {
    return 'InventoryEvent(eventId: $eventId, sku: $sku, action: $action, '
        'quantity: $quantity, unit: $unit, timestamp: $timestamp, metadata: $metadata)';
  }
}

class InventoryState {
  final String sku;
  final double onHand;
  final double reserved;
  final double available;
  final List<String> appliedEvents;

  const InventoryState({
    required this.sku,
    required this.onHand,
    required this.reserved,
    required this.available,
    required this.appliedEvents,
  });

  InventoryState copyWith({
    String? sku,
    double? onHand,
    double? reserved,
    double? available,
    List<String>? appliedEvents,
  }) {
    return InventoryState(
      sku: sku ?? this.sku,
      onHand: onHand ?? this.onHand,
      reserved: reserved ?? this.reserved,
      available: available ?? this.available,
      appliedEvents: appliedEvents ?? this.appliedEvents,
    );
  }

  @override
  String toString() {
    return 'InventoryState(sku: $sku, onHand: ${onHand.toStringAsFixed(2)}, '
        'reserved: ${reserved.toStringAsFixed(2)}, available: ${available.toStringAsFixed(2)})';
  }
}

class ReconcileIssue {
  final String code;
  final String message;
  final String? eventId;

  const ReconcileIssue({
    required this.code,
    required this.message,
    this.eventId,
  });

  @override
  String toString() {
    if (eventId == null) return 'Issue[$code]: $message';
    return 'Issue[$code]($eventId): $message';
  }
}

class ReconcileReport {
  final int totalInput;
  final int applied;
  final int rejected;
  final int deduplicated;
  final int reordered;
  final Map<String, InventoryState> finalStates;
  final List<ReconcileIssue> issues;

  const ReconcileReport({
    required this.totalInput,
    required this.applied,
    required this.rejected,
    required this.deduplicated,
    required this.reordered,
    required this.finalStates,
    required this.issues,
  });

  String pretty() {
    final lines = <String>[
      'Inventory Reconcile Report',
      '--------------------------',
      'Total input : $totalInput',
      'Applied     : $applied',
      'Rejected    : $rejected',
      'Deduplicated: $deduplicated',
      'Reordered   : $reordered',
      'SKU states  : ${finalStates.length}',
      '',
      'Final states:',
    ];

    final skus = finalStates.keys.toList()..sort();
    for (final sku in skus) {
      lines.add('- ${finalStates[sku]}');
    }

    if (issues.isNotEmpty) {
      lines.add('');
      lines.add('Issues:');
      for (final issue in issues.take(20)) {
        lines.add('- $issue');
      }
    }

    return lines.join('\n');
  }
}

class _Normalize {
  static const _validActions = <String>{
    'IN',
    'OUT',
    'ADJUST',
    'RESERVE',
    'RELEASE',
  };

  static const _unitToPiece = <String, double>{
    'piece': 1.0,
    'box': 10.0,
    'carton': 100.0,
  };

  static String cleanId(String value) {
    return value.trim().toUpperCase();
  }

  static String cleanSku(String value) {
    final v = value.trim().toUpperCase();
    return v.replaceAll(' ', '');
  }

  static String cleanAction(String value) {
    final action = value.trim().toUpperCase();
    if (_validActions.contains(action)) return action;
    return 'INVALID';
  }

  static String cleanUnit(String value) {
    final unit = value.trim().toLowerCase();
    if (_unitToPiece.containsKey(unit)) return unit;
    return 'piece';
  }

  static double normalizeQuantity(double qty, String unit) {
    final rate = _unitToPiece[unit] ?? 1.0;
    if (qty.isNaN || qty.isInfinite) return 0;
    if (qty < 0) return 0;
    return qty * rate;
  }

  static InventoryEvent normalizeEvent(InventoryEvent event) {
    final eventId = cleanId(event.eventId);
    final sku = cleanSku(event.sku);
    final action = cleanAction(event.action);
    final unit = cleanUnit(event.unit);
    final quantityInPiece = normalizeQuantity(event.quantity, unit);

    final metadata = <String, String>{};
    for (final e in event.metadata.entries) {
      final k = e.key.trim().toLowerCase();
      final v = e.value.trim();
      if (k.isNotEmpty && v.isNotEmpty) {
        metadata[k] = v;
      }
    }

    return event.copyWith(
      eventId: eventId,
      sku: sku,
      action: action,
      quantity: quantityInPiece,
      unit: 'piece',
      metadata: metadata,
    );
  }
}

class _Validate {
  static ReconcileIssue? validate(InventoryEvent event) {
    if (event.eventId.isEmpty) {
      return const ReconcileIssue(code: 'E_EMPTY_ID', message: 'Empty event ID');
    }
    if (event.sku.isEmpty) {
      return ReconcileIssue(
        code: 'E_EMPTY_SKU',
        message: 'Empty SKU',
        eventId: event.eventId,
      );
    }
    if (event.action == 'INVALID') {
      return ReconcileIssue(
        code: 'E_INVALID_ACTION',
        message: 'Unsupported action',
        eventId: event.eventId,
      );
    }
    if (event.quantity <= 0 && event.action != 'ADJUST') {
      return ReconcileIssue(
        code: 'E_NON_POSITIVE_QTY',
        message: 'Quantity must be > 0 for non-adjust actions',
        eventId: event.eventId,
      );
    }
    return null;
  }
}

class _Sorter {
  static List<InventoryEvent> byTimeThenId(List<InventoryEvent> events) {
    final cloned = List<InventoryEvent>.from(events);
    cloned.sort((a, b) {
      final t = a.timestamp.compareTo(b.timestamp);
      if (t != 0) return t;
      return a.eventId.compareTo(b.eventId);
    });
    return cloned;
  }
}

class InventoryReconciler {
  final List<ReconcileIssue> _issues = [];

  List<ReconcileIssue> get issues => List.unmodifiable(_issues);

  void _issue(String code, String message, {String? eventId}) {
    _issues.add(ReconcileIssue(code: code, message: message, eventId: eventId));
  }

  ReconcileReport reconcile(List<InventoryEvent> input) {
    return reconcileWithInitialState(input);
  }

  ReconcileReport reconcileWithInitialState(
    List<InventoryEvent> input, {
    Map<String, InventoryState>? initialStates,
    bool resetIssues = true,
  }) {
    if (resetIssues) {
      _issues.clear();
    }

    final normalized = input.map(_Normalize.normalizeEvent).toList();

    final uniqueById = <String, InventoryEvent>{};
    var deduplicated = 0;
    for (final event in normalized) {
      final existing = uniqueById[event.eventId];
      if (existing == null) {
        uniqueById[event.eventId] = event;
      } else {
        deduplicated++;
        final keep = _pickBetter(existing, event);
        uniqueById[event.eventId] = keep;
        _issue(
          'W_DUPLICATE_EVENT',
          'Duplicate event ID detected; kept one version',
          eventId: event.eventId,
        );
      }
    }

    final unsorted = uniqueById.values.toList();
    final sorted = _Sorter.byTimeThenId(unsorted);

    var reordered = 0;
    for (var i = 0; i < unsorted.length && i < sorted.length; i++) {
      if (unsorted[i].eventId != sorted[i].eventId) {
        reordered++;
      }
    }

    final states = <String, InventoryState>{
      if (initialStates != null) ...initialStates,
    };
    var applied = 0;
    var rejected = 0;

    for (final event in sorted) {
      final error = _Validate.validate(event);
      if (error != null) {
        _issues.add(error);
        rejected++;
        continue;
      }

      final state = states[event.sku] ?? InventoryState(
        sku: event.sku,
        onHand: 0,
        reserved: 0,
        available: 0,
        appliedEvents: const <String>[],
      );

      final next = _applyEvent(state, event);
      if (next == null) {
        rejected++;
        continue;
      }

      states[event.sku] = next;
      applied++;
    }

    return ReconcileReport(
      totalInput: input.length,
      applied: applied,
      rejected: rejected,
      deduplicated: deduplicated,
      reordered: reordered,
      finalStates: states,
      issues: List.unmodifiable(_issues),
    );
  }

  InventoryEvent _pickBetter(InventoryEvent a, InventoryEvent b) {
    // Prefer larger metadata richness; if tie, prefer later timestamp.
    final scoreA = a.metadata.length;
    final scoreB = b.metadata.length;
    if (scoreB > scoreA) return b;
    if (scoreA > scoreB) return a;
    return b.timestamp.isAfter(a.timestamp) ? b : a;
  }

  InventoryState? _applyEvent(InventoryState current, InventoryEvent e) {
    var onHand = current.onHand;
    var reserved = current.reserved;

    if (e.action == 'IN') {
      onHand += e.quantity;
    } else if (e.action == 'OUT') {
      if (e.quantity > current.available) {
        _issue(
          'E_NEGATIVE_AVAILABLE',
          'OUT exceeds available stock',
          eventId: e.eventId,
        );
        return null;
      }
      onHand -= e.quantity;
    } else if (e.action == 'ADJUST') {
      // ADJUST sets absolute onHand. Quantity was normalized to piece.
      onHand = e.quantity;
      if (reserved > onHand) {
        reserved = onHand;
        _issue(
          'W_RESERVED_CLAMPED',
          'Reserved stock clamped after ADJUST',
          eventId: e.eventId,
        );
      }
    } else if (e.action == 'RESERVE') {
      final available = onHand - reserved;
      if (e.quantity > available) {
        _issue(
          'E_RESERVE_EXCEEDS_AVAILABLE',
          'RESERVE exceeds available stock',
          eventId: e.eventId,
        );
        return null;
      }
      reserved += e.quantity;
    } else if (e.action == 'RELEASE') {
      if (e.quantity > reserved) {
        _issue(
          'W_RELEASE_CLAMPED',
          'RELEASE exceeds reserved; clamped to reserved',
          eventId: e.eventId,
        );
        reserved = 0;
      } else {
        reserved -= e.quantity;
      }
    }

    // Hard safety clamps for numeric drift.
    if (onHand < 0) {
      _issue('E_NEGATIVE_ON_HAND', 'onHand became negative', eventId: e.eventId);
      return null;
    }
    if (reserved < 0) {
      _issue('E_NEGATIVE_RESERVED', 'reserved became negative', eventId: e.eventId);
      return null;
    }
    if (reserved > onHand) {
      _issue(
        'W_RESERVED_GT_ON_HAND',
        'reserved > onHand; clamped to onHand',
        eventId: e.eventId,
      );
      reserved = onHand;
    }

    final available = onHand - reserved;
    final applied = <String>[...current.appliedEvents, e.eventId];

    return current.copyWith(
      onHand: _round2(onHand),
      reserved: _round2(reserved),
      available: _round2(available),
      appliedEvents: applied,
    );
  }

  double _round2(double x) {
    final f = 100.0;
    return (x * f).round() / f;
  }
}

class BatchReconcileRunner {
  final InventoryReconciler reconciler;

  const BatchReconcileRunner(this.reconciler);

  List<ReconcileReport> runByChunks(
    List<InventoryEvent> events, {
    int chunkSize = 500,
  }) {
    if (chunkSize <= 0) {
      throw ArgumentError('chunkSize must be > 0');
    }

    final reports = <ReconcileReport>[];
    for (var i = 0; i < events.length; i += chunkSize) {
      final end = (i + chunkSize < events.length) ? i + chunkSize : events.length;
      reports.add(reconciler.reconcile(events.sublist(i, end)));
    }
    return reports;
  }

  ReconcileReport runSequentialChunks(
    List<InventoryEvent> events, {
    int chunkSize = 500,
  }) {
    if (chunkSize <= 0) {
      throw ArgumentError('chunkSize must be > 0');
    }

    var totalInput = 0;
    var applied = 0;
    var rejected = 0;
    var deduplicated = 0;
    var reordered = 0;
    final mergedIssues = <ReconcileIssue>[];
    var carryStates = <String, InventoryState>{};

    for (var i = 0; i < events.length; i += chunkSize) {
      final end = (i + chunkSize < events.length) ? i + chunkSize : events.length;
      final chunk = events.sublist(i, end);
      final report = reconciler.reconcileWithInitialState(
        chunk,
        initialStates: carryStates,
        resetIssues: true,
      );

      totalInput += report.totalInput;
      applied += report.applied;
      rejected += report.rejected;
      deduplicated += report.deduplicated;
      reordered += report.reordered;
      mergedIssues.addAll(report.issues);
      carryStates = Map<String, InventoryState>.from(report.finalStates);
    }

    return ReconcileReport(
      totalInput: totalInput,
      applied: applied,
      rejected: rejected,
      deduplicated: deduplicated,
      reordered: reordered,
      finalStates: carryStates,
      issues: mergedIssues,
    );
  }

  ReconcileReport mergeReports(List<ReconcileReport> reports) {
    var totalInput = 0;
    var applied = 0;
    var rejected = 0;
    var deduplicated = 0;
    var reordered = 0;
    final mergedStates = <String, InventoryState>{};
    final mergedIssues = <ReconcileIssue>[];

    for (final r in reports) {
      totalInput += r.totalInput;
      applied += r.applied;
      rejected += r.rejected;
      deduplicated += r.deduplicated;
      reordered += r.reordered;
      mergedIssues.addAll(r.issues);

      for (final entry in r.finalStates.entries) {
        final existing = mergedStates[entry.key];
        if (existing == null) {
          mergedStates[entry.key] = entry.value;
        } else {
          final onHand = existing.onHand + entry.value.onHand;
          final reserved = existing.reserved + entry.value.reserved;
          final available = onHand - reserved;
          mergedStates[entry.key] = existing.copyWith(
            onHand: onHand,
            reserved: reserved,
            available: available,
            appliedEvents: <String>[
              ...existing.appliedEvents,
              ...entry.value.appliedEvents,
            ],
          );
        }
      }
    }

    return ReconcileReport(
      totalInput: totalInput,
      applied: applied,
      rejected: rejected,
      deduplicated: deduplicated,
      reordered: reordered,
      finalStates: mergedStates,
      issues: mergedIssues,
    );
  }
}

List<InventoryEvent> sampleEvents(DateTime base) {
  return <InventoryEvent>[
    InventoryEvent(
      eventId: 'e-001',
      sku: 'tea-milk',
      action: 'IN',
      quantity: 3,
      unit: 'box',
      timestamp: base.add(const Duration(minutes: 10)),
      metadata: const {'source': 'import'},
    ),
    InventoryEvent(
      eventId: 'e-002',
      sku: 'tea-milk',
      action: 'RESERVE',
      quantity: 5,
      unit: 'piece',
      timestamp: base.add(const Duration(minutes: 20)),
      metadata: const {'order': 'o-1001'},
    ),
    InventoryEvent(
      eventId: 'e-003',
      sku: 'tea-milk',
      action: 'OUT',
      quantity: 2,
      unit: 'piece',
      timestamp: base.add(const Duration(minutes: 30)),
      metadata: const {'note': 'waste'},
    ),
    InventoryEvent(
      eventId: 'e-003', // duplicate id on purpose
      sku: 'tea-milk',
      action: 'OUT',
      quantity: 2,
      unit: 'piece',
      timestamp: base.add(const Duration(minutes: 31)),
      metadata: const {'note': 'duplicate-replay', 'extra': 'yes'},
    ),
    InventoryEvent(
      eventId: 'e-004',
      sku: 'orange-juice',
      action: 'IN',
      quantity: 1,
      unit: 'carton',
      timestamp: base.add(const Duration(minutes: 5)),
      metadata: const {'source': 'stocktake'},
    ),
    InventoryEvent(
      eventId: 'e-005',
      sku: 'orange-juice',
      action: 'RESERVE',
      quantity: 999,
      unit: 'piece',
      timestamp: base.add(const Duration(minutes: 40)),
      metadata: const {'order': 'o-1002'},
    ),
    InventoryEvent(
      eventId: ' e-006 ',
      sku: ' orange-juice ',
      action: 'release',
      quantity: 30,
      unit: 'piece',
      timestamp: base.add(const Duration(minutes: 50)),
      metadata: const {'order': 'o-1002'},
    ),
    InventoryEvent(
      eventId: 'e-007',
      sku: 'cake-choco',
      action: 'ADJUST',
      quantity: 12,
      unit: 'piece',
      timestamp: base.add(const Duration(minutes: 60)),
      metadata: const {'reason': 'manual count'},
    ),
    InventoryEvent(
      eventId: 'e-008',
      sku: 'cake-choco',
      action: 'OUT',
      quantity: 20,
      unit: 'piece',
      timestamp: base.add(const Duration(minutes: 70)),
      metadata: const {'note': 'over consume'},
    ),
    InventoryEvent(
      eventId: 'e-009',
      sku: 'cake-choco',
      action: 'OUT',
      quantity: 1,
      unit: 'box',
      timestamp: base.add(const Duration(minutes: 80)),
      metadata: const {'note': 'bulk use'},
    ),
    InventoryEvent(
      eventId: 'e-010',
      sku: '',
      action: 'IN',
      quantity: 4,
      unit: 'piece',
      timestamp: base.add(const Duration(minutes: 90)),
      metadata: const {},
    ),
    InventoryEvent(
      eventId: 'e-011',
      sku: 'sugar-pack',
      action: 'UNKNOWN',
      quantity: 3,
      unit: 'piece',
      timestamp: base.add(const Duration(minutes: 100)),
      metadata: const {},
    ),
  ];
}

void runAssertions(ReconcileReport report) {
  if (report.totalInput <= 0) {
    throw StateError('Expected non-empty input');
  }

  if (report.applied <= 0) {
    throw StateError('Expected at least one applied event');
  }

  for (final state in report.finalStates.values) {
    if (state.onHand < 0 || state.reserved < 0 || state.available < 0) {
      throw StateError('Negative inventory detected in final state for ${state.sku}');
    }
    if ((state.onHand - state.reserved - state.available).abs() > 0.0001) {
      throw StateError('State invariant broken for ${state.sku}');
    }
  }
}

void main() {
  final base = DateTime.utc(2026, 3, 22, 8, 0, 0);
  final events = sampleEvents(base);

  final reconciler = InventoryReconciler();
  final batch = BatchReconcileRunner(reconciler);

  // Fixed approach: process chunks sequentially with carry-over state.
  final merged = batch.runSequentialChunks(events, chunkSize: 5);

  print(merged.pretty());
  runAssertions(merged);
  print('\nStandalone long inventory reconciler executed successfully.');
}
