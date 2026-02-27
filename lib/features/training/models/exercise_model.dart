enum ExerciseType { hold, reps }

class Exercise {
  final String id;
  final String name;
  final String description;
  final ExerciseType type;
  final int targetValue; // Seconds for hold, Reps for reps
  final int sets;
  final int restSeconds;

  Exercise({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.targetValue,
    required this.sets,
    required this.restSeconds,
  });
}

class WorkoutPlan {
  final String id;
  final String title;
  final List<Exercise> exercises;

  WorkoutPlan({required this.id, required this.title, required this.exercises});
}
