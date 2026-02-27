import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

final poseDetectorProvider = Provider.autoDispose<PoseDetector>((ref) {
  final options = PoseDetectorOptions(mode: PoseDetectionMode.stream);
  final detector = PoseDetector(options: options);

  ref.onDispose(() {
    detector.close();
  });

  return detector;
});
