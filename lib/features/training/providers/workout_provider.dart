import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/exercise_model.dart';

class WorkoutState {
  final WorkoutPlan plan;
  final int currentExerciseIndex;
  final int currentSet;
  final int timerSeconds;
  final bool isTimerRunning;
  final bool isRestMode;

  WorkoutState({
    required this.plan,
    this.currentExerciseIndex = 0,
    this.currentSet = 1,
    this.timerSeconds = 0,
    this.isTimerRunning = false,
    this.isRestMode = false,
  });

  Exercise get currentExercise => plan.exercises[currentExerciseIndex];

  WorkoutState copyWith({
    int? currentExerciseIndex,
    int? currentSet,
    int? timerSeconds,
    bool? isTimerRunning,
    bool? isRestMode,
  }) {
    return WorkoutState(
      plan: this.plan,
      currentExerciseIndex: currentExerciseIndex ?? this.currentExerciseIndex,
      currentSet: currentSet ?? this.currentSet,
      timerSeconds: timerSeconds ?? this.timerSeconds,
      isTimerRunning: isTimerRunning ?? this.isTimerRunning,
      isRestMode: isRestMode ?? this.isRestMode,
    );
  }
}

class WorkoutNotifier extends StateNotifier<WorkoutState> {
  Timer? _timer;

  WorkoutNotifier(WorkoutPlan plan) : super(WorkoutState(plan: plan));

  void startTimer() {
    _timer?.cancel();
    state = state.copyWith(isTimerRunning: true);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.timerSeconds > 0) {
        state = state.copyWith(timerSeconds: state.timerSeconds - 1);
      } else {
        stopTimer();
        if (state.isRestMode) {
          // Finish rest, continue to next work
          state = state.copyWith(isRestMode: false);
        }
      }
    });
  }

  void stopTimer() {
    _timer?.cancel();
    state = state.copyWith(isTimerRunning: false);
  }

  void finishSet() {
    if (state.currentSet < state.currentExercise.sets) {
      // Start rest
      state = state.copyWith(
        currentSet: state.currentSet + 1,
        timerSeconds: state.currentExercise.restSeconds,
        isRestMode: true,
      );
      startTimer();
    } else {
      // Next exercise
      if (state.currentExerciseIndex < state.plan.exercises.length - 1) {
        state = state.copyWith(
          currentExerciseIndex: state.currentExerciseIndex + 1,
          currentSet: 1,
          isRestMode: false,
        );
      } else {
        // Workout Finished
        // TODO: Handle completion
      }
    }
  }

  void resetTimer(int seconds) {
    stopTimer();
    state = state.copyWith(timerSeconds: seconds);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

final workoutPlanProvider = Provider<WorkoutPlan>((ref) {
  return WorkoutPlan(
    id: 'tuck_planche_基础',
    title: 'タックプランシェ基礎',
    exercises: [
      Exercise(
        id: 'planche_lean',
        name: 'プランシェ リーン',
        description: '体を前に倒し、肩で支える姿勢をキープします。',
        type: ExerciseType.hold,
        targetValue: 20,
        sets: 3,
        restSeconds: 60,
      ),
      Exercise(
        id: 'scapula_shrugs',
        name: '肩甲骨シュラッグ',
        description: '腕を伸ばしたまま肩甲骨を押し下げる・引き上げる動作を繰り返します。',
        type: ExerciseType.reps,
        targetValue: 12,
        sets: 3,
        restSeconds: 60,
      ),
      Exercise(
        id: 'tuck_planche_hold',
        name: 'タックプランシェ ホールド',
        description: '膝をお腹に近づけ、体を浮かせます。',
        type: ExerciseType.hold,
        targetValue: 10,
        sets: 3,
        restSeconds: 90,
      ),
    ],
  );
});

final workoutProvider = StateNotifierProvider<WorkoutNotifier, WorkoutState>((
  ref,
) {
  final plan = ref.watch(workoutPlanProvider);
  return WorkoutNotifier(plan);
});
