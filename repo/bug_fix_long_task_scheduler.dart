/// Standalone long bug-fix style module
///
/// Purpose:
/// - Provide a robust task scheduler that fixes common bugs found in simple
///   scheduling scripts:
///   1) invalid time ranges
///   2) circular dependencies
///   3) duplicate tasks
///   4) broken priority sorting
///   5) unstable overlap handling
///
/// This file is fully standalone and does not rely on project code outside repo.

class Task {
  final String id;
  final String title;
  final int priority;
  final int durationMinutes;
  final DateTime earliestStart;
  final DateTime latestEnd;
  final List<String> dependsOn;
  final Map<String, String> tags;

  const Task({
    required this.id,
    required this.title,
    required this.priority,
    required this.durationMinutes,
    required this.earliestStart,
    required this.latestEnd,
    required this.dependsOn,
    required this.tags,
  });

  Task copyWith({
    String? id,
    String? title,
    int? priority,
    int? durationMinutes,
    DateTime? earliestStart,
    DateTime? latestEnd,
    List<String>? dependsOn,
    Map<String, String>? tags,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      priority: priority ?? this.priority,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      earliestStart: earliestStart ?? this.earliestStart,
      latestEnd: latestEnd ?? this.latestEnd,
      dependsOn: dependsOn ?? this.dependsOn,
      tags: tags ?? this.tags,
    );
  }

  @override
  String toString() {
    return 'Task(id: $id, title: $title, priority: $priority, '
        'durationMinutes: $durationMinutes, earliestStart: $earliestStart, '
        'latestEnd: $latestEnd, dependsOn: $dependsOn, tags: $tags)';
  }
}

class ScheduledTask {
  final Task task;
  final DateTime start;
  final DateTime end;

  const ScheduledTask({
    required this.task,
    required this.start,
    required this.end,
  });

  int get duration => end.difference(start).inMinutes;

  @override
  String toString() {
    return 'ScheduledTask(taskId: ${task.id}, start: ${start.toIso8601String()}, '
        'end: ${end.toIso8601String()}, duration: $duration)';
  }
}

class RejectedTask {
  final Task task;
  final String reason;

  const RejectedTask(this.task, this.reason);

  @override
  String toString() => 'RejectedTask(task: ${task.id}, reason: $reason)';
}

class ScheduleReport {
  final List<ScheduledTask> accepted;
  final List<RejectedTask> rejected;
  final Duration totalWorkingTime;
  final int overlapResolutions;
  final int dependencyDepth;

  const ScheduleReport({
    required this.accepted,
    required this.rejected,
    required this.totalWorkingTime,
    required this.overlapResolutions,
    required this.dependencyDepth,
  });

  String pretty() {
    final lines = <String>[
      'Schedule Report',
      '---------------',
      'Accepted tasks      : ${accepted.length}',
      'Rejected tasks      : ${rejected.length}',
      'Total working mins  : ${totalWorkingTime.inMinutes}',
      'Overlap resolutions : $overlapResolutions',
      'Dependency depth    : $dependencyDepth',
      '',
      'Accepted:',
    ];

    for (final s in accepted) {
      lines.add(
        '- ${s.task.id} [p${s.task.priority}] ${s.start.toIso8601String()} -> ${s.end.toIso8601String()}',
      );
    }

    if (rejected.isNotEmpty) {
      lines.add('');
      lines.add('Rejected:');
      for (final r in rejected) {
        lines.add('- ${r.task.id}: ${r.reason}');
      }
    }

    return lines.join('\n');
  }
}

class _Validation {
  static String _normalizeId(String id) {
    return id.trim().toUpperCase();
  }

  static Task normalizeTask(Task task) {
    final fixedId = _normalizeId(task.id);
    final fixedTitle = task.title.trim().isEmpty ? 'Untitled' : task.title.trim();

    var fixedPriority = task.priority;
    if (fixedPriority < 0) fixedPriority = 0;
    if (fixedPriority > 10) fixedPriority = 10;

    var fixedDuration = task.durationMinutes;
    if (fixedDuration < 1) fixedDuration = 1;
    if (fixedDuration > 24 * 60) fixedDuration = 24 * 60;

    DateTime fixedEarliest = task.earliestStart;
    DateTime fixedLatest = task.latestEnd;

    if (!fixedEarliest.isBefore(fixedLatest)) {
      fixedLatest = fixedEarliest.add(Duration(minutes: fixedDuration));
    }

    final fixedDepends = task.dependsOn
        .map(_normalizeId)
        .where((e) => e.isNotEmpty && e != fixedId)
        .toSet()
        .toList();

    final fixedTags = <String, String>{};
    for (final entry in task.tags.entries) {
      final key = entry.key.trim().toLowerCase();
      final value = entry.value.trim();
      if (key.isNotEmpty && value.isNotEmpty) {
        fixedTags[key] = value;
      }
    }

    return task.copyWith(
      id: fixedId,
      title: fixedTitle,
      priority: fixedPriority,
      durationMinutes: fixedDuration,
      earliestStart: fixedEarliest,
      latestEnd: fixedLatest,
      dependsOn: fixedDepends,
      tags: fixedTags,
    );
  }

  static List<Task> normalizeAll(List<Task> tasks) {
    return tasks.map(normalizeTask).toList();
  }
}

class _Graph {
  final Map<String, List<String>> edges;

  const _Graph(this.edges);

  factory _Graph.fromTasks(List<Task> tasks) {
    final map = <String, List<String>>{};
    for (final t in tasks) {
      map.putIfAbsent(t.id, () => <String>[]);
      for (final dep in t.dependsOn) {
        map.putIfAbsent(dep, () => <String>[]);
        map[dep]!.add(t.id);
      }
    }
    return _Graph(map);
  }

  bool hasCycle() {
    final visiting = <String>{};
    final visited = <String>{};

    bool dfs(String node) {
      if (visiting.contains(node)) return true;
      if (visited.contains(node)) return false;

      visiting.add(node);
      final neighbors = edges[node] ?? const <String>[];
      for (final n in neighbors) {
        if (dfs(n)) return true;
      }
      visiting.remove(node);
      visited.add(node);
      return false;
    }

    for (final key in edges.keys) {
      if (dfs(key)) return true;
    }
    return false;
  }
}

class _Ordering {
  static List<Task> topoSortByDependencies(List<Task> tasks) {
    final byId = <String, Task>{for (final t in tasks) t.id: t};
    final indegree = <String, int>{for (final t in tasks) t.id: 0};
    final outgoing = <String, List<String>>{for (final t in tasks) t.id: <String>[]};

    for (final t in tasks) {
      for (final dep in t.dependsOn) {
        if (byId.containsKey(dep)) {
          outgoing.putIfAbsent(dep, () => <String>[]).add(t.id);
          indegree[t.id] = (indegree[t.id] ?? 0) + 1;
        }
      }
    }

    final queue = <String>[];
    indegree.forEach((id, d) {
      if (d == 0) queue.add(id);
    });

    queue.sort((a, b) {
      final ta = byId[a]!;
      final tb = byId[b]!;
      if (ta.priority != tb.priority) return tb.priority.compareTo(ta.priority);
      return a.compareTo(b);
    });

    final result = <Task>[];
    var idx = 0;

    while (idx < queue.length) {
      final currentId = queue[idx++];
      final current = byId[currentId];
      if (current == null) continue;
      result.add(current);

      for (final nxt in outgoing[currentId] ?? const <String>[]) {
        indegree[nxt] = (indegree[nxt] ?? 0) - 1;
        if (indegree[nxt] == 0) {
          queue.add(nxt);
          final start = idx;
          final tail = queue.sublist(start)
            ..sort((a, b) {
              final ta = byId[a]!;
              final tb = byId[b]!;
              if (ta.priority != tb.priority) return tb.priority.compareTo(ta.priority);
              return a.compareTo(b);
            });
          for (var i = 0; i < tail.length; i++) {
            queue[start + i] = tail[i];
          }
        }
      }
    }

    final placedIds = result.map((t) => t.id).toSet();
    final remaining = tasks.where((t) => !placedIds.contains(t.id)).toList()
      ..sort((a, b) {
        if (a.priority != b.priority) return b.priority.compareTo(a.priority);
        return a.id.compareTo(b.id);
      });

    return <Task>[...result, ...remaining];
  }

  static int dependencyDepth(List<Task> tasks) {
    final byId = <String, Task>{for (final t in tasks) t.id: t};
    final memo = <String, int>{};

    int dfs(String id, Set<String> stack) {
      if (memo.containsKey(id)) return memo[id]!;
      if (!byId.containsKey(id)) return 0;
      if (stack.contains(id)) return 0;

      stack.add(id);
      var best = 0;
      for (final dep in byId[id]!.dependsOn) {
        final v = 1 + dfs(dep, stack);
        if (v > best) best = v;
      }
      stack.remove(id);
      memo[id] = best;
      return best;
    }

    var depth = 0;
    for (final id in byId.keys) {
      final d = dfs(id, <String>{});
      if (d > depth) depth = d;
    }
    return depth;
  }
}

class _Overlap {
  static bool intersects(DateTime s1, DateTime e1, DateTime s2, DateTime e2) {
    return s1.isBefore(e2) && s2.isBefore(e1);
  }

  static DateTime clampStart(DateTime proposed, Task task) {
    if (proposed.isBefore(task.earliestStart)) return task.earliestStart;
    return proposed;
  }

  static DateTime calculateEnd(DateTime start, Task task) {
    return start.add(Duration(minutes: task.durationMinutes));
  }

  static bool fitsWindow(DateTime start, Task task) {
    final end = calculateEnd(start, task);
    return !end.isAfter(task.latestEnd);
  }
}

class RobustTaskScheduler {
  ScheduleReport buildSchedule(List<Task> inputTasks, DateTime scheduleStart) {
    final normalized = _Validation.normalizeAll(inputTasks);

    final unique = <String, Task>{};
    final rejected = <RejectedTask>[];

    for (final t in normalized) {
      final prev = unique[t.id];
      if (prev == null) {
        unique[t.id] = t;
      } else {
        final pick = _pickBetterDuplicate(prev, t);
        unique[t.id] = pick;
      }
    }

    final tasks = unique.values.toList();

    final graph = _Graph.fromTasks(tasks);
    if (graph.hasCycle()) {
      for (final t in tasks) {
        rejected.add(RejectedTask(t, 'Circular dependency detected'));
      }
      return ScheduleReport(
        accepted: const <ScheduledTask>[],
        rejected: rejected,
        totalWorkingTime: Duration.zero,
        overlapResolutions: 0,
        dependencyDepth: 0,
      );
    }

    final ordered = _Ordering.topoSortByDependencies(tasks);
    final byId = <String, ScheduledTask>{};
    final accepted = <ScheduledTask>[];
    var overlapResolutions = 0;

    var cursor = scheduleStart;

    for (final task in ordered) {
      DateTime start = _Overlap.clampStart(cursor, task);

      for (final depId in task.dependsOn) {
        final dep = byId[depId];
        if (dep != null && dep.end.isAfter(start)) {
          start = dep.end;
        }
      }

      var end = _Overlap.calculateEnd(start, task);

      if (!_Overlap.fitsWindow(start, task)) {
        rejected.add(RejectedTask(task, 'Task does not fit time window'));
        continue;
      }

      var changed = true;
      while (changed) {
        changed = false;
        for (final taken in accepted) {
          if (_Overlap.intersects(start, end, taken.start, taken.end)) {
            start = taken.end;
            end = _Overlap.calculateEnd(start, task);
            overlapResolutions++;
            changed = true;
          }
        }
      }

      if (!_Overlap.fitsWindow(start, task)) {
        rejected.add(RejectedTask(task, 'Task overlaps and cannot be shifted'));
        continue;
      }

      final scheduled = ScheduledTask(task: task, start: start, end: end);
      accepted.add(scheduled);
      byId[task.id] = scheduled;

      if (end.isAfter(cursor)) {
        cursor = end;
      }
    }

    accepted.sort((a, b) => a.start.compareTo(b.start));

    Duration total = Duration.zero;
    for (final s in accepted) {
      total += Duration(minutes: s.duration);
    }

    final depth = _Ordering.dependencyDepth(tasks);

    return ScheduleReport(
      accepted: accepted,
      rejected: rejected,
      totalWorkingTime: total,
      overlapResolutions: overlapResolutions,
      dependencyDepth: depth,
    );
  }

  Task _pickBetterDuplicate(Task a, Task b) {
    final scoreA = _taskScore(a);
    final scoreB = _taskScore(b);
    if (scoreB > scoreA) return b;
    return a;
  }

  int _taskScore(Task t) {
    var score = 0;
    score += t.priority * 100;
    score += t.tags.length * 2;
    score -= t.dependsOn.length;
    score += t.durationMinutes ~/ 10;
    return score;
  }
}

List<Task> generateSampleTasks(DateTime base) {
  return <Task>[
    Task(
      id: 't1',
      title: 'Prepare data feed',
      priority: 9,
      durationMinutes: 45,
      earliestStart: base,
      latestEnd: base.add(const Duration(hours: 8)),
      dependsOn: const <String>[],
      tags: const {'team': 'core', 'type': 'prep'},
    ),
    Task(
      id: 'T2',
      title: 'Run parser',
      priority: 8,
      durationMinutes: 35,
      earliestStart: base,
      latestEnd: base.add(const Duration(hours: 8)),
      dependsOn: const <String>['t1'],
      tags: const {'team': 'core', 'type': 'compute'},
    ),
    Task(
      id: 't3',
      title: 'Validate output',
      priority: 7,
      durationMinutes: 50,
      earliestStart: base,
      latestEnd: base.add(const Duration(hours: 9)),
      dependsOn: const <String>['t2'],
      tags: const {'team': 'qa'},
    ),
    Task(
      id: 't4',
      title: 'Generate report',
      priority: 6,
      durationMinutes: 30,
      earliestStart: base.add(const Duration(minutes: 15)),
      latestEnd: base.add(const Duration(hours: 10)),
      dependsOn: const <String>['t3'],
      tags: const {'team': 'qa', 'format': 'pdf'},
    ),
    Task(
      id: 't5',
      title: 'Publish artifact',
      priority: 5,
      durationMinutes: 20,
      earliestStart: base,
      latestEnd: base.add(const Duration(hours: 10)),
      dependsOn: const <String>['t4'],
      tags: const {'team': 'ops'},
    ),
    Task(
      id: 't6',
      title: 'Legacy duplicate higher priority',
      priority: 10,
      durationMinutes: 25,
      earliestStart: base,
      latestEnd: base.add(const Duration(hours: 6)),
      dependsOn: const <String>[],
      tags: const {'team': 'ops', 'duplicate': 'yes'},
    ),
    Task(
      id: 't6',
      title: 'Legacy duplicate lower priority',
      priority: 4,
      durationMinutes: 25,
      earliestStart: base,
      latestEnd: base.add(const Duration(hours: 6)),
      dependsOn: const <String>[],
      tags: const {'team': 'old'},
    ),
    Task(
      id: 't7',
      title: 'Backfill inventory',
      priority: 3,
      durationMinutes: 95,
      earliestStart: base.add(const Duration(hours: 7)),
      latestEnd: base.add(const Duration(hours: 7, minutes: 30)),
      dependsOn: const <String>[],
      tags: const {'team': 'support'},
    ),
    Task(
      id: 't8',
      title: 'Audit logs',
      priority: 6,
      durationMinutes: 40,
      earliestStart: base,
      latestEnd: base.add(const Duration(hours: 10)),
      dependsOn: const <String>['t5'],
      tags: const {'team': 'security'},
    ),
    Task(
      id: 't9',
      title: 'Cleanup temp files',
      priority: -2,
      durationMinutes: 0,
      earliestStart: base.add(const Duration(hours: 1)),
      latestEnd: base.add(const Duration(hours: 2)),
      dependsOn: const <String>[],
      tags: const {'team': 'ops'},
    ),
    Task(
      id: '  ',
      title: 'Bad id task',
      priority: 3,
      durationMinutes: 20,
      earliestStart: base,
      latestEnd: base.add(const Duration(hours: 2)),
      dependsOn: const <String>[],
      tags: const {'bad': 'id'},
    ),
  ];
}

void runSelfChecks(ScheduleReport report) {
  if (report.accepted.isEmpty && report.rejected.isEmpty) {
    throw StateError('Scheduler returned empty report unexpectedly');
  }

  for (final s in report.accepted) {
    if (!s.start.isBefore(s.end)) {
      throw StateError('Invalid scheduled interval for ${s.task.id}');
    }
    if (s.end.isAfter(s.task.latestEnd)) {
      throw StateError('Scheduled task exceeds latestEnd for ${s.task.id}');
    }
    if (s.start.isBefore(s.task.earliestStart)) {
      throw StateError('Scheduled task starts before earliestStart for ${s.task.id}');
    }
  }

  for (var i = 0; i < report.accepted.length; i++) {
    for (var j = i + 1; j < report.accepted.length; j++) {
      final a = report.accepted[i];
      final b = report.accepted[j];
      final overlap = a.start.isBefore(b.end) && b.start.isBefore(a.end);
      if (overlap) {
        throw StateError('Unexpected overlap between ${a.task.id} and ${b.task.id}');
      }
    }
  }
}

void main() {
  final base = DateTime.utc(2026, 3, 20, 8, 0, 0);
  final tasks = generateSampleTasks(base);

  final scheduler = RobustTaskScheduler();
  final report = scheduler.buildSchedule(tasks, base);

  print(report.pretty());
  runSelfChecks(report);
  print('\nStandalone long task scheduler executed successfully.');
}
