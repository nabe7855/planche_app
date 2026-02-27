import 'package:hive/hive.dart';

part 'user_profile.g.dart';

@HiveType(typeId: 0)
class UserProfile extends HiveObject {
  @HiveField(0)
  String name;

  @HiveField(1)
  double? weight;

  @HiveField(2)
  String? targetGoal;

  @HiveField(3)
  String? experienceLevel;

  @HiveField(4)
  List<String> injuryHistory;

  @HiveField(5)
  List<String> currentPainAreas;

  @HiveField(6)
  DateTime? lastUpdate;

  UserProfile({
    required this.name,
    this.weight,
    this.targetGoal,
    this.experienceLevel,
    this.injuryHistory = const [],
    this.currentPainAreas = const [],
    this.lastUpdate,
  });
}
