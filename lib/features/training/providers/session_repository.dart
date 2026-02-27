import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/training_session.dart';

// Hiveボックス名の定数
const kTrainingSessionBox = 'training_sessions';

// セッションを保存・同期するRepositoryのProvider
final sessionRepositoryProvider = Provider<SessionRepository>((ref) {
  return SessionRepository();
});

// セッション履歴の一覧を提供するProvider
final trainingHistoryProvider = FutureProvider<List<TrainingSession>>((
  ref,
) async {
  final repo = ref.read(sessionRepositoryProvider);

  // クラウドから最新データを同期する（非同期で待機）
  await repo.syncFromCloud();

  // ローカル（Hive）からデータを読み込む
  final box = await Hive.openBox<TrainingSession>(kTrainingSessionBox);

  // 日付の新しい順に並べる
  final sessions = box.values.toList()
    ..sort((a, b) => b.date.compareTo(a.date));
  return sessions;
});

class SessionRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> saveSession(TrainingSession session) async {
    // 1. ローカル(Hive)に保存
    final box = await Hive.openBox<TrainingSession>(kTrainingSessionBox);
    await box.add(session);

    // 2. ログインしていればクラウド(Firestore)にも保存
    final user = _auth.currentUser;
    if (user != null) {
      try {
        await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('sessions')
            .add(session.toMap());
      } catch (e) {
        print('Firestore save error: $e');
        // オフラインなどで失敗してもローカルには保存されているので続行可能
      }
    }
  }

  Future<void> syncFromCloud() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('sessions')
          .get();

      if (snapshot.docs.isEmpty) return;

      final box = await Hive.openBox<TrainingSession>(kTrainingSessionBox);

      // 簡易的な同期：Firestoreにあってローカルにないものを追加
      // 本来はIDベースでマージする等の設計が望ましいが、今回は日付をキーにして重複チェック
      final existingDates = box.values
          .map((e) => e.date.toIso8601String())
          .toSet();

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final session = TrainingSession.fromMap(data);

        if (!existingDates.contains(session.date.toIso8601String())) {
          await box.add(session);
          existingDates.add(session.date.toIso8601String()); // 重複追加を防ぐ
        }
      }
    } catch (e) {
      print('Firestore sync error: $e');
    }
  }

  Future<List<TrainingSession>> getRecentSessions({int limit = 7}) async {
    final box = await Hive.openBox<TrainingSession>(kTrainingSessionBox);
    final sessions = box.values.toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    return sessions.take(limit).toList();
  }
}
