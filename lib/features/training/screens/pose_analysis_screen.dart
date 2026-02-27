import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

import '../../../core/theme.dart';
import '../models/training_session.dart';
import '../providers/pose_detector_provider.dart';
import '../providers/session_repository.dart';

class PoseAnalysisScreen extends ConsumerStatefulWidget {
  const PoseAnalysisScreen({super.key});

  @override
  ConsumerState<PoseAnalysisScreen> createState() => _PoseAnalysisScreenState();
}

enum PlancheStatus { notDetected, measuring, locked, warning }

class _PoseAnalysisScreenState extends ConsumerState<PoseAnalysisScreen> {
  CameraController? _cameraController;
  bool _isBusy = false;
  CustomPaint? _customPaint;
  String? _message;
  PlancheStatus _status = PlancheStatus.notDetected;
  int _cameraIndex = -1;

  // Analysis Stats
  double _leftElbowAngle = 0;
  double _leanAmount = 0;

  // Auto-Timer
  Timer? _holdTimer;
  int _holdMilliseconds = 0; // 現在のホールド時間（ms）
  int _bestHoldMilliseconds = 0; // セッション中の最長ホールド（ms）
  int _totalHoldMilliseconds = 0; // セッション中の累計ホールド（ms）
  int _holdCount = 0; // 成功したホールドの回数
  bool _wasLocked = false;

  @override
  void initState() {
    super.initState();
    _startLiveFeed();
  }

  @override
  void dispose() {
    _holdTimer?.cancel();
    _saveSession(); // 画面を閉じる時にセッションを保存
    _stopLiveFeed();
    super.dispose();
  }

  Future<void> _saveSession() async {
    // ホールドが1回以上あればセッションとして保存
    if (_holdCount == 0 && _bestHoldMilliseconds < 1000) return;
    final session = TrainingSession(
      date: DateTime.now(),
      bestHoldMs: _bestHoldMilliseconds,
      totalHoldMs: _totalHoldMilliseconds,
      holdCount: _holdCount,
      planName: 'タックプランシェ基礎',
    );
    final repo = ref.read(sessionRepositoryProvider);
    await repo.saveSession(session);
  }

  @override
  Widget build(BuildContext context) {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('AI フォーム解析'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Transform.scale(scale: 1.0, child: CameraPreview(_cameraController!)),
          if (_customPaint != null) _customPaint!,

          // Analysis Overlay (Top)
          Positioned(
            top: 20,
            left: 24,
            right: 24,
            child: Column(
              children: [
                _buildStatusBadge(),
                const SizedBox(height: 12),
                _buildAnalysisCard(),
              ],
            ),
          ),

          // Hold Timer Ring (center of screen, visible only when locked)
          if (_status == PlancheStatus.locked || _holdMilliseconds > 0)
            Center(
              child: AnimatedOpacity(
                opacity: _status == PlancheStatus.locked ? 1.0 : 0.4,
                duration: const Duration(milliseconds: 300),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 180,
                      height: 180,
                      child: CircularProgressIndicator(
                        value: (_holdMilliseconds % 10000) / 10000,
                        strokeWidth: 8,
                        backgroundColor: Colors.white10,
                        color: _getStatusColor(),
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _formatMs(_holdMilliseconds),
                          style: TextStyle(
                            color: _getStatusColor(),
                            fontSize: 44,
                            fontWeight: FontWeight.bold,
                            shadows: [
                              Shadow(color: Colors.black, blurRadius: 8),
                            ],
                          ),
                        ),
                        Text(
                          'ホールド中',
                          style: TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

          // Message (Bottom Center)
          Positioned(
            bottom: 120,
            left: 24,
            right: 24,
            child: Center(
              child: AnimatedOpacity(
                opacity: _message != null ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 300),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: _getStatusColor().withOpacity(0.5),
                      width: 2,
                    ),
                  ),
                  child: Text(
                    _message ?? '',
                    style: TextStyle(
                      color: _getStatusColor(),
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Close Button
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Center(
              child: FloatingActionButton.large(
                onPressed: () => Navigator.pop(context),
                backgroundColor: Colors.white,
                child: const Icon(Icons.close, color: Colors.black, size: 32),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge() {
    String label = '検出待ち';
    IconData icon = Icons.person_search;
    Color color = Colors.grey;

    switch (_status) {
      case PlancheStatus.notDetected:
        label = '検出待ち';
        break;
      case PlancheStatus.measuring:
        label = '解析中';
        color = Colors.blueAccent;
        icon = Icons.sync;
        break;
      case PlancheStatus.locked:
        label = 'LOCKED';
        color = AppTheme.primaryColor;
        icon = Icons.lock;
        break;
      case PlancheStatus.warning:
        label = 'WARNING';
        color = Colors.orangeAccent;
        icon = Icons.warning_amber_rounded;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.9),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalysisCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStatItem(
            '肘の角度',
            '${_leftElbowAngle.toStringAsFixed(0)}°',
            _leftElbowAngle > 165 ? AppTheme.primaryColor : Colors.orangeAccent,
          ),
          Container(width: 1, height: 30, color: Colors.white10),
          _buildStatItem(
            'リーン量',
            '${_leanAmount.toStringAsFixed(0)}',
            _leanAmount > 50 ? AppTheme.primaryColor : Colors.white60,
          ),
          Container(width: 1, height: 30, color: Colors.white10),
          _buildStatItem(
            'ベスト (秒)',
            _formatMs(_bestHoldMilliseconds),
            Colors.amberAccent,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color valueColor) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white54, fontSize: 12),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Color _getStatusColor() {
    switch (_status) {
      case PlancheStatus.locked:
        return AppTheme.primaryColor;
      case PlancheStatus.warning:
        return Colors.orangeAccent;
      case PlancheStatus.measuring:
        return Colors.blueAccent;
      default:
        return Colors.white;
    }
  }

  Future _startLiveFeed() async {
    final cameras = await availableCameras();
    _cameraIndex = cameras.indexWhere(
      (camera) => camera.lensDirection == CameraLensDirection.back,
    );

    if (_cameraIndex == -1) _cameraIndex = 0;

    final camera = cameras[_cameraIndex];
    _cameraController = CameraController(
      camera,
      ResolutionPreset.high,
      enableAudio: false,
    );

    _cameraController!.initialize().then((_) {
      if (!mounted) return;
      _cameraController!.startImageStream(_processCameraImage);
      setState(() {});
    });
  }

  Future _stopLiveFeed() async {
    await _cameraController?.stopImageStream();
    await _cameraController?.dispose();
    _cameraController = null;
  }

  void _processCameraImage(CameraImage image) {
    final inputImage = _inputImageFromCameraImage(image);
    if (inputImage == null) return;
    _processImage(inputImage);
  }

  final _orientations = {
    DeviceOrientation.portraitUp: 0,
    DeviceOrientation.landscapeLeft: 90,
    DeviceOrientation.portraitDown: 180,
    DeviceOrientation.landscapeRight: 270,
  };

  InputImage? _inputImageFromCameraImage(CameraImage image) {
    if (_cameraController == null) return null;

    final sensorOrientation = _cameraController!.description.sensorOrientation;
    InputImageRotation? rotation;
    if (Platform.isIOS) {
      rotation = InputImageRotationValue.fromRawValue(sensorOrientation);
    } else if (Platform.isAndroid) {
      var rotationCompensation =
          _orientations[_cameraController!.value.deviceOrientation];
      if (rotationCompensation == null) return null;
      if (_cameraController!.description.lensDirection ==
          CameraLensDirection.front) {
        rotationCompensation = (sensorOrientation + rotationCompensation) % 360;
      } else {
        rotationCompensation =
            (sensorOrientation - rotationCompensation + 360) % 360;
      }
      rotation = InputImageRotationValue.fromRawValue(rotationCompensation);
    }
    if (rotation == null) return null;

    final format = InputImageFormatValue.fromRawValue(image.format.raw);
    if (format == null ||
        (Platform.isAndroid && format != InputImageFormat.nv21) ||
        (Platform.isIOS && format != InputImageFormat.bgra8888))
      return null;

    if (image.planes.length != 1) return null;
    final plane = image.planes.first;

    return InputImage.fromBytes(
      bytes: plane.bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: format,
        bytesPerRow: plane.bytesPerRow,
      ),
    );
  }

  Future<void> _processImage(InputImage inputImage) async {
    if (_isBusy) return;
    _isBusy = true;

    final detector = ref.read(poseDetectorProvider);
    final poses = await detector.processImage(inputImage);

    if (poses.isEmpty) {
      _status = PlancheStatus.notDetected;
      _message = '全身が映るように離れてください';
    } else {
      final pose = poses.first;
      _analyzePlancheForm(pose);

      if (inputImage.metadata?.size != null &&
          inputImage.metadata?.rotation != null) {
        final painter = PosePainter(
          poses,
          inputImage.metadata!.size,
          inputImage.metadata!.rotation,
          _cameraController!.description.lensDirection,
          _getStatusColor(),
        );
        _customPaint = CustomPaint(painter: painter);
      }
    }

    // Auto-timer: start/stop based on lock status
    _updateHoldTimer();

    _isBusy = false;
    if (mounted) {
      setState(() {});
    }
  }

  void _updateHoldTimer() {
    final isLocked = _status == PlancheStatus.locked;
    if (isLocked && !_wasLocked) {
      // LOCKEDになった → タイマー開始
      _holdTimer?.cancel();
      _holdTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
        if (mounted) {
          setState(() {
            _holdMilliseconds += 100;
            if (_holdMilliseconds > _bestHoldMilliseconds) {
              _bestHoldMilliseconds = _holdMilliseconds;
            }
          });
        }
      });
    } else if (!isLocked && _wasLocked) {
      // LOCKEDが解除された → タイマー停止、累計に加算
      _holdTimer?.cancel();
      if (_holdMilliseconds >= 500) {
        // 0.5秒以上なら有効なホールドとしてカウント
        _totalHoldMilliseconds += _holdMilliseconds;
        _holdCount++;
      }
      _holdMilliseconds = 0;
    }
    _wasLocked = isLocked;
  }

  String _formatMs(int ms) {
    final seconds = ms ~/ 1000;
    final tenths = (ms % 1000) ~/ 100;
    return '$seconds.$tenths';
  }

  void _analyzePlancheForm(Pose pose) {
    final leftShoulder = pose.landmarks[PoseLandmarkType.leftShoulder];
    final leftElbow = pose.landmarks[PoseLandmarkType.leftElbow];
    final leftWrist = pose.landmarks[PoseLandmarkType.leftWrist];

    if (leftShoulder != null && leftElbow != null && leftWrist != null) {
      // 1. Calculate Elbow Angle (Straightness)
      _leftElbowAngle = _calculateAngle(leftShoulder, leftElbow, leftWrist);

      // 2. Calculate Lean (Horizontal offset between shoulder and wrist)
      _leanAmount = (leftShoulder.x - leftWrist.x).abs();

      // 3. Status Logic
      if (_leftElbowAngle < 160) {
        _status = PlancheStatus.warning;
        _message = '腕を伸ばしましょう！';
      } else if (_leanAmount < 40) {
        _status = PlancheStatus.measuring;
        _message = 'もっと前に倒れましょう';
      } else {
        _status = PlancheStatus.locked;
        _message = 'いいフォームです！キープ！';
      }
    } else {
      _status = PlancheStatus.measuring;
      _message = '体が正しく認識されていません';
    }
  }

  double _calculateAngle(PoseLandmark p1, PoseLandmark p2, PoseLandmark p3) {
    double angle =
        math.atan2(p3.y - p2.y, p3.x - p2.x) -
        math.atan2(p1.y - p2.y, p1.x - p2.x);
    angle = angle.abs() * 180.0 / math.pi;
    if (angle > 180) angle = 360 - angle;
    return angle;
  }
}

class PosePainter extends CustomPainter {
  PosePainter(
    this.poses,
    this.absoluteImageSize,
    this.rotation,
    this.cameraLensDirection,
    this.accentColor,
  );

  final List<Pose> poses;
  final Size absoluteImageSize;
  final InputImageRotation rotation;
  final CameraLensDirection cameraLensDirection;
  final Color accentColor;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0
      ..color = accentColor;

    for (final pose in poses) {
      pose.landmarks.forEach((_, landmark) {
        canvas.drawCircle(
          Offset(
            _translateX(landmark.x, rotation, size, absoluteImageSize),
            _translateY(landmark.y, rotation, size, absoluteImageSize),
          ),
          4,
          paint..style = PaintingStyle.fill,
        );
      });
    }
  }

  @override
  bool shouldRepaint(PosePainter oldDelegate) {
    return oldDelegate.absoluteImageSize != absoluteImageSize ||
        oldDelegate.poses != poses;
  }

  double _translateX(
    double x,
    InputImageRotation rotation,
    Size size,
    Size absoluteImageSize,
  ) {
    switch (rotation) {
      case InputImageRotation.rotation90deg:
        return x * size.width / absoluteImageSize.height;
      case InputImageRotation.rotation270deg:
        return size.width - x * size.width / absoluteImageSize.height;
      default:
        return x * size.width / absoluteImageSize.width;
    }
  }

  double _translateY(
    double y,
    InputImageRotation rotation,
    Size size,
    Size absoluteImageSize,
  ) {
    switch (rotation) {
      case InputImageRotation.rotation90deg:
      case InputImageRotation.rotation270deg:
        return y * size.height / absoluteImageSize.width;
      default:
        return y * size.height / absoluteImageSize.height;
    }
  }
}
