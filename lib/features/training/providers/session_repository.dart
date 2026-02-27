import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/training_session.dart';

// Hiveボックス名の定数
const kTrainingSessionBox = 'training_sessions';

// セッション履歴の一覧を提供するProvider
final trainingHistoryProvider = FutureProvider<List<TrainingSession>>((
  ref,
) async {
  final box = await Hive.openBox<TrainingSession>(kTrainingSessionBox);
  // 日付の新しい順に並べる
  final sessions = box.values.toList()
    ..sort((a, b) => b.date.compareTo(a.date));
  return sessions;
});

// セッションを保存するProvider（関数を提供）
final sessionRepositoryProvider = Provider<SessionRepository>((ref) {
  return SessionRepository();
});

class SessionRepository {
  Future<void> saveSession(TrainingSession session) async {
    final box = await Hive.openBox<TrainingSession>(kTrainingSessionBox);
    await box.add(session);
  }

  Future<List<TrainingSession>> getRecentSessions({int limit = 7}) async {
    final box = await Hive.openBox<TrainingSession>(kTrainingSessionBox);
    final sessions = box.values.toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    return sessions.take(limit).toList();
  }
}
