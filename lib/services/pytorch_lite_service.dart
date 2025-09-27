import 'dart:io';
import 'package:pytorch_lite/pytorch_lite.dart';
import 'dart:math' show max, min;

enum ModelType { yoloV8 }

class MedicineModelConfig {
  final String modelPath;
  final String? labelsPath;
  final int inputW;
  final int inputH;

  const MedicineModelConfig({
    required this.modelPath,
    required this.labelsPath,
    this.inputW = 960,
    this.inputH = 960,
  });
}

class PerImageScores {
  final double authSum;   // raw sum of confidences for 'authentic'
  final double fakeSum;   // raw sum of confidences for 'counterfeit'
  final double authScore; // capped to [0,1], used for averaging
  final double fakeScore; // capped to [0,1], used for averaging
  PerImageScores({
    required this.authSum,
    required this.fakeSum,
    required this.authScore,
    required this.fakeScore,
  });
}

const double kMinBoxConf = 0.50; // ignore boxes below this conf entirely
const double kConflictSumMin = 0.60; // class is "present" if SUM >= this
const double kStrongBoxConf = 0.60; // ...or if any single box >= this
const double kMultiItemConf = 0.5;  // Minimum confidence for counting boxes toward "items"
const double kClusterIoU = 0.5; // Boxes with IoU >= this are considered the same pack

class ConflictDetectionException implements Exception {
  final String message;
  ConflictDetectionException([
    this.message = 'Detected both AUTHENTIC and COUNTERFEIT in the same image.',
  ]);
  @override
  String toString() => message;
}

class MultipleItemsDetectedException implements Exception {
  final String location; // "FRONT" or "BACK"
  MultipleItemsDetectedException(this.location);

  @override
  String toString() => 'Multiple medicine packs detected in the $location image.';
}

class AnalysisResult {
  final double avgAuthenticScore;      // 0..1 (from capped sums)
  final double avgCounterfeitScore;    // 0..1 (from capped sums)
  final double frontAuthenticScore;
  final double backAuthenticScore;
  final String finalLabel;    // 'authentic' | 'counterfeit' | 'inconclusive'

  AnalysisResult({
    required this.avgAuthenticScore,
    required this.avgCounterfeitScore,
    required this.frontAuthenticScore,
    required this.backAuthenticScore,
    required this.finalLabel,
  });
}

class ModelService {
  static final ModelService _i = ModelService._();
  factory ModelService() => _i;
  ModelService._();

  static const double decisionThreshold = 0.75; // 75%

  // Register medicines here.
  //   authentic
  //   counterfeit
  final Map<String, MedicineModelConfig> _registry = {
    'Biogesic': const MedicineModelConfig(
      modelPath: 'assets/models/biogesic.torchscript',
      labelsPath: 'assets/labels/labels.txt',
      inputW: 960,
      inputH: 960,
    ),
    'Neozep': const MedicineModelConfig(
      modelPath: 'assets/models/neozep.torchscript',
      labelsPath: 'assets/labels/labels.txt',
      inputW: 960,
      inputH: 960,
    ),
  };

  final Map<String, dynamic> _loaded = {}; // cached YOLO models per medicine

  Future<void> preload(String medicine) async {
    await _ensureLoaded(medicine);
  }

  Future<void> _ensureLoaded(String medicine) async {
    final cfg = _registry[medicine];
    if (cfg == null) throw Exception('No model registered for $medicine.');
    if (_loaded.containsKey(medicine)) return;

    final model = await PytorchLite.loadObjectDetectionModel(
      cfg.modelPath,
      2, // authentic + counterfeit
      cfg.inputW,
      cfg.inputH,
      labelPath: cfg.labelsPath,
      objectDetectionModelType: ObjectDetectionModelType.yolov8,
    );
    _loaded[medicine] = model;
  }

  Future<PerImageScores> scoreOne({
    required String medicine,
    required File image,
    String tag = 'image',
  }) async {
    await _ensureLoaded(medicine);
    final model = _loaded[medicine];
    return await _scoreImageYolo(model: model, imageFile: image, tag: tag);
  }

  // ---- Scoring for a single image (YOLOv8) ----
  // Sum confidences for each class; this is more robust than taking only the max box.
  Future<PerImageScores> _scoreImageYolo({
    required dynamic model,
    required File imageFile,
    String tag = 'image',
  }) async {
    final bytes = await imageFile.readAsBytes();
    final dets = await model.getImagePrediction(
      bytes,
      minimumScore: kMinBoxConf,
      iOUThreshold: 0.45,
    ) as List<ResultObjectDetection>;

    final strongBoxes = dets
        .where((d) => (d.score ?? 0.0) >= kMultiItemConf)
        .toList();

    double iou(ResultObjectDetection a, ResultObjectDetection b) {
      final ax1 = a.rect.left,   ay1 = a.rect.top;
      final ax2 = a.rect.right,  ay2 = a.rect.bottom;
      final bx1 = b.rect.left,   by1 = b.rect.top;
      final bx2 = b.rect.right,  by2 = b.rect.bottom;

      final ix1 = max(ax1, bx1);
      final iy1 = max(ay1, by1);
      final ix2 = min(ax2, bx2);
      final iy2 = min(ay2, by2);

      final iw = max(0.0, ix2 - ix1);
      final ih = max(0.0, iy2 - iy1);
      final inter = iw * ih;

      final areaA = max(0.0, (ax2 - ax1)) * max(0.0, (ay2 - ay1));
      final areaB = max(0.0, (bx2 - bx1)) * max(0.0, (by2 - by1));
      final denom = areaA + areaB - inter;
      if (denom <= 0.0) return 0.0;
      return inter / denom;
    }

    // Cluster strong boxes by IoU
    if (strongBoxes.isNotEmpty) {
      final visited = List<bool>.filled(strongBoxes.length, false);
      int clusters = 0;

      for (int i = 0; i < strongBoxes.length; i++) {
        if (visited[i]) continue;
        visited[i] = true;
        clusters++;

        // BFS cluster merge
        final queue = <int>[i];
        while (queue.isNotEmpty) {
          final idx = queue.removeLast();
          for (int j = 0; j < strongBoxes.length; j++) {
            if (visited[j]) continue;
            if (iou(strongBoxes[idx], strongBoxes[j]) >= kClusterIoU) {
              visited[j] = true;
              queue.add(j);
            }
          }
        }
      }

      if (clusters > 1) {
        print('[ModelService][$tag] multiple packs detected: clusters=$clusters');
        throw MultipleItemsDetectedException(tag.toUpperCase());
      }
    }

    double authSum = 0.0;
    double fakeSum = 0.0;
    bool authHasStrong = false;
    bool fakeHasStrong = false;

    for (final d in dets) {
      final name = (d.className ?? '').toLowerCase().trim();
      final conf = (d.score ?? 0.0).clamp(0.0, 1.0);
      if (name == 'authentic') {
        authSum += conf;
        if (conf >= kStrongBoxConf) authHasStrong = true;
      } else if (name == 'counterfeit') {
        fakeSum += conf;
        if (conf >= kStrongBoxConf) fakeHasStrong = true;
      }
    }

    // Debug logs
    print('[ModelService][$tag] auth_sum=${authSum.toStringAsFixed(3)} '
        'fake_sum=${fakeSum.toStringAsFixed(3)} '
        'authStrong=$authHasStrong fakeStrong=$fakeHasStrong '
        '(minBox=$kMinBoxConf sumMin=$kConflictSumMin strong=$kStrongBoxConf)');

    // tolerant conflict test
    final bool authPresent = (authSum >= kConflictSumMin) || authHasStrong;
    final bool fakePresent = (fakeSum >= kConflictSumMin) || fakeHasStrong;

    if (authPresent && fakePresent) {
      print('[ModelService][$tag] conflict -> both classes present by thresholds');
      throw ConflictDetectionException();
    }

    // Evidence scores for averaging/display: cap to [0,1]
    final authScore = authSum.clamp(0.0, 1.0);
    final fakeScore = fakeSum.clamp(0.0, 1.0);

    // Per-image verdict (your 0.75 rule)
    final perImageVerdict =
    (authScore >= ModelService.decisionThreshold) ? 'authentic'
        : (fakeScore >= ModelService.decisionThreshold) ? 'counterfeit'
        : 'inconclusive';

    print('[ModelService][$tag] auth=${(authScore*100).toStringAsFixed(1)}% '
        'fake=${(fakeScore*100).toStringAsFixed(1)}% → $perImageVerdict');

    return PerImageScores(
      authSum: authSum,
      fakeSum: fakeSum,
      authScore: authScore,
      fakeScore: fakeScore,
    );
  }

  // analyze both images and average the scores ----
  Future<AnalysisResult> analyzeBoth({
    required String medicine,
    required File front,
    required File back,
  }) async {
    await _ensureLoaded(medicine);
    final model = _loaded[medicine];

    // May throw ConflictDetectionException if an image contains both classes
    final f = await _scoreImageYolo(model: model, imageFile: front, tag: 'front');
    final b = await _scoreImageYolo(model: model, imageFile: back,  tag: 'back');

    // Average the capped evidence scores (not normalized)
    final avgAuth = ((f.authScore + b.authScore) / 2.0).clamp(0.0, 1.0);
    final avgFake = ((f.fakeScore + b.fakeScore) / 2.0).clamp(0.0, 1.0);

    // exact rule:
    //   avgAuthentic ≥ 0.75 → Authentic
    //   avgCounterfeit ≥ 0.75 → Counterfeit
    //   else → Inconclusive
    late final String label;
    if (avgAuth >= ModelService.decisionThreshold) {
      label = 'authentic';
    } else if (avgFake >= ModelService.decisionThreshold) {
      label = 'counterfeit';
    } else {
      label = 'inconclusive';
    }

    print('[ModelService][avg] auth=${(avgAuth*100).toStringAsFixed(1)}% '
        'fake=${(avgFake*100).toStringAsFixed(1)}% → $label');

    return AnalysisResult(
      avgAuthenticScore: avgAuth,
      avgCounterfeitScore: avgFake,
      frontAuthenticScore: f.authScore,
      backAuthenticScore:  b.authScore,
      finalLabel: label,
    );
  }
}
