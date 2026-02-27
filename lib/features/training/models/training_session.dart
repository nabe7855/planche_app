import 'package:hive/hive.dart';

part 'training_session.g.dart';

// typeId: 1 (UserProfileはtypeId: 0)
@HiveType(typeId: 1)
class TrainingSession extends HiveObject {
  @HiveField(0)
  DateTime date;

  @HiveField(1)
  int bestHoldMs; // セッション中の最長ホールド時間（ミリ秒）

  @HiveField(2)
  int totalHoldMs; // セッション中の合計ホールド時間（ミリ秒）

  @HiveField(3)
  int holdCount; // 成功したホールドの回数

  @HiveField(4)
  String planName; // 使用したトレーニングプランの名前

  TrainingSession({
    required this.date,
    required this.bestHoldMs,
    required this.totalHoldMs,
    required this.holdCount,
    required this.planName,
  });

  // 最長ホールドを秒数（小数点1桁）で表示するヘルパー
  String get bestHoldFormatted {
    final seconds = bestHoldMs ~/ 1000;
    final tenths = (bestHoldMs % 1000) ~/ 100;
    return '$seconds.$tenths秒';
  }

  // 合計ホールドを秒数で表示するヘルパー
  double get bestHoldSeconds => bestHoldMs / 1000.0;
}
