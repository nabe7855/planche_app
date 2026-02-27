import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme.dart';
import '../providers/workout_provider.dart';
import 'pose_analysis_screen.dart';

class TrainingScreen extends ConsumerWidget {
  const TrainingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workoutState = ref.watch(workoutProvider);
    final currentExercise = workoutState.currentExercise;

    return Scaffold(
      appBar: AppBar(
        title: Text(workoutState.plan.title),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Exercise Info
              Text(
                '${currentExercise.name} (${workoutState.currentSet}/${currentExercise.sets}セット)',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                '目標キープ時間: 20秒',
                style: TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 48),

              // Timer Display (Circular Progress Indicator)
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 200,
                    height: 200,
                    child: CircularProgressIndicator(
                      value:
                          workoutState.timerSeconds /
                          currentExercise.targetValue,
                      strokeWidth: 8,
                      backgroundColor: Colors.white10,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  Text(
                    '${workoutState.timerSeconds}s',
                    style: const TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 48),

              // Training Tips / Description
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  currentExercise.description,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70),
                ),
              ),

              const Spacer(),

              // Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      if (workoutState.isTimerRunning) {
                        ref.read(workoutProvider.notifier).stopTimer();
                      } else {
                        ref.read(workoutProvider.notifier).startTimer();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: workoutState.isTimerRunning
                          ? AppTheme.accentColor
                          : AppTheme.primaryColor,
                    ),
                    child: Text(workoutState.isTimerRunning ? 'ストップ' : 'スタート'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const PoseAnalysisScreen(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('AI解析'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      ref.read(workoutProvider.notifier).finishSet();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[800],
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('完了'),
                  ),
                ],
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
