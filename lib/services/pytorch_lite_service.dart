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

class MedicineMismatchException implements Exception {
  final String detectedMedicine;
  final String selectedMedicine;
  MedicineMismatchException(this.detectedMedicine, this.selectedMedicine);

  @override
  String toString() => 'Detected $detectedMedicine but selected $selectedMedicine.';
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

// Simple containers for identifier results to avoid record syntax issues
class IdentResult {
  final String name;
  final double confidence;
  const IdentResult(this.name, this.confidence);
}

class IdentPair {
  final IdentResult front;
  final IdentResult back;
  const IdentPair({required this.front, required this.back});
}

// Decision container for a single image vs selected medicine
class IdentDecision {
  final String bestName;        // top-1 predicted class name
  final double bestConfidence;  // top-1 confidence 0..1
  final bool matchesSelected;   // bestName == selected AND conf >= threshold
  const IdentDecision({
    required this.bestName,
    required this.bestConfidence,
    required this.matchesSelected,
  });
}

class ModelService {
  static final ModelService _i = ModelService._();
  factory ModelService() => _i;
  ModelService._();

  static const double decisionThreshold = 0.75; // 75%
  // Use the same confidence threshold for identifier as the medicine models
  static const double identifierConfidenceThreshold = decisionThreshold;
  static const double strongIdentifierThreshold = 0.85; // strong disagreement threshold

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
    'Bioflu': const MedicineModelConfig(
      modelPath: 'assets/models/bioflu.torchscript',
      labelsPath: 'assets/labels/labels.txt',
      inputW: 960,
      inputH: 960,
    ),
    'Alaxan': const MedicineModelConfig(
      modelPath: 'assets/models/alaxan.torchscript',
      labelsPath: 'assets/labels/labels.txt',
      inputW: 960,
      inputH: 960,
    ),
    'Medicol': const MedicineModelConfig(
      modelPath: 'assets/models/medicol.torchscript',
      labelsPath: 'assets/labels/labels.txt',
      inputW: 960,
      inputH: 960,
    ),
  };

  // Identifier model configuration
  static const MedicineModelConfig _identifierConfig = MedicineModelConfig(
    modelPath: 'assets/models/identifier.torchscript',
      labelsPath: 'assets/labels/identifier.txt',
    inputW: 960,
    inputH: 960,
  );

  final Map<String, dynamic> _loaded = {}; // cached YOLO models per medicine
  dynamic _identifierModel; // cached identifier model

  Future<void> preload(String medicine) async {
    await _ensureLoaded(medicine);
  }

  Future<void> preloadIdentifier() async {
    await _ensureIdentifierLoaded();
  }

  // Preload identifier and all medicine models to avoid first-use lag
  Future<void> preloadAll() async {
    // Load identifier model
    await _ensureIdentifierLoaded();
    // Load all registered medicine models
    for (final medicine in _registry.keys) {
      try {
        await _ensureLoaded(medicine);
      } catch (_) {
        // If a specific model fails to load, continue loading others
        // This ensures the app still becomes responsive.
      }
    }
  }

  Future<void> _ensureLoaded(String medicine) async {
    final cfg = _registry[medicine];
    if (cfg == null) throw Exception('No model registered for $medicine.');
    if (_loaded.containsKey(medicine)) return;

    try {
      final model = await PytorchLite.loadObjectDetectionModel(
        cfg.modelPath,
        2, // authentic + counterfeit
        cfg.inputW,
        cfg.inputH,
        labelPath: cfg.labelsPath,
        objectDetectionModelType: ObjectDetectionModelType.yolov8,
      );
      _loaded[medicine] = model;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> _ensureIdentifierLoaded() async {
    if (_identifierModel != null) return;

    try {
      final model = await PytorchLite.loadObjectDetectionModel(
        _identifierConfig.modelPath,
        5, // 5 medicine types: Biogesic, Neozep, Bioflu, Alaxan, Medicol
        _identifierConfig.inputW,
        _identifierConfig.inputH,
        labelPath: _identifierConfig.labelsPath,
        objectDetectionModelType: ObjectDetectionModelType.yolov8,
      );
      _identifierModel = model;
    } catch (e) {
      rethrow;
    }
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

  Future<String> identifyMedicine(File image) async {
    await _ensureIdentifierLoaded();
    
    final bytes = await image.readAsBytes();
    final dets = await _identifierModel.getImagePrediction(
      bytes,
      minimumScore: 0.3, // Lower threshold for identification
      iOUThreshold: 0.45,
    ) as List<ResultObjectDetection>;

    if (dets.isEmpty) {
      throw Exception('No medicine detected in image');
    }

    // Find the detection with highest confidence
    ResultObjectDetection bestDetection = dets.first;
    for (final det in dets) {
      if ((det.score ?? 0.0) > (bestDetection.score ?? 0.0)) {
        bestDetection = det;
      }
    }

    final detectedClass = bestDetection.className?.toLowerCase().trim() ?? '';
    final confidence = bestDetection.score ?? 0.0;

    // Map detected class to medicine name
    String medicineName;
    switch (detectedClass) {
      case 'biogesic':
        medicineName = 'Biogesic';
        break;
      case 'neozep':
        medicineName = 'Neozep';
        break;
      case 'bioflu':
        medicineName = 'Bioflu';
        break;
      case 'alaxan':
        medicineName = 'Alaxan';
        break;
      case 'medicol':
        medicineName = 'Medicol';
        break;
      default:
        throw Exception('Unknown medicine type detected: $detectedClass');
    }

    return medicineName;
  }

  // Returns the detected medicine and its confidence.
  Future<IdentResult> identifyOne(File image) async {
    await _ensureIdentifierLoaded();

    final bytes = await image.readAsBytes();
    final dets = await _identifierModel.getImagePrediction(
      bytes,
      minimumScore: 0.25,
      iOUThreshold: 0.45,
    ) as List<ResultObjectDetection>;

    if (dets.isEmpty) {
      return const IdentResult('unknown', 0.0);
    }

    ResultObjectDetection bestDetection = dets.first;
    for (final det in dets) {
      if ((det.score ?? 0.0) > (bestDetection.score ?? 0.0)) {
        bestDetection = det;
      }
    }

    final detectedClass = bestDetection.className?.toLowerCase().trim() ?? '';
    final conf = (bestDetection.score ?? 0.0).clamp(0.0, 1.0);

    String name;
    switch (detectedClass) {
      case 'biogesic': name = 'Biogesic'; break;
      case 'neozep':   name = 'Neozep';   break;
      case 'bioflu':   name = 'Bioflu';   break;
      case 'alaxan':   name = 'Alaxan';   break;
      case 'medicol':  name = 'Medicol';  break;
      default:         name = 'unknown';  break;
    }

    return IdentResult(name, conf);
  }

  // Identify from both images; returns both results and a recommended decision
  Future<IdentPair> identifyBoth({required File front, required File back}) async {
    final f = await identifyOne(front);
    final b = await identifyOne(back);
    return IdentPair(front: f, back: b);
  }

  // Return max confidence per class for an image (identifier model)
  Future<Map<String, double>> identifyScores(File image) async {
    await _ensureIdentifierLoaded();

    final bytes = await image.readAsBytes();
    final dets = await _identifierModel.getImagePrediction(
      bytes,
      minimumScore: 0.25,
      iOUThreshold: 0.45,
    ) as List<ResultObjectDetection>;

    final Map<String, double> scores = {
      'Biogesic': 0.0,
      'Neozep': 0.0,
      'Bioflu': 0.0,
      'Alaxan': 0.0,
      'Medicol': 0.0,
    };

    String mapName(String raw) {
      switch (raw.toLowerCase().trim()) {
        case 'biogesic': return 'Biogesic';
        case 'neozep':   return 'Neozep';
        case 'bioflu':   return 'Bioflu';
        case 'alaxan':   return 'Alaxan';
        case 'medicol':  return 'Medicol';
        default:         return 'unknown';
      }
    }

    for (final d in dets) {
      final name = mapName(d.className ?? '');
      if (name == 'unknown') continue;
      final conf = (d.score ?? 0.0).clamp(0.0, 1.0);
      if (conf > (scores[name] ?? 0.0)) {
        scores[name] = conf;
      }
    }

    return scores;
  }

  // Simple front-check style: take top-1 prediction and compare to selected
  Future<IdentDecision> identifySelected(File image, String selected) async {
    await _ensureIdentifierLoaded();

    final bytes = await image.readAsBytes();
    final dets = await _identifierModel.getImagePrediction(
      bytes,
      minimumScore: 0.05,
      iOUThreshold: 0.45,
    ) as List<ResultObjectDetection>;

    if (dets.isEmpty) {
      return const IdentDecision(bestName: 'unknown', bestConfidence: 0.0, matchesSelected: false);
    }

    ResultObjectDetection best = dets.first;
    for (final d in dets) {
      if ((d.score ?? 0.0) > (best.score ?? 0.0)) best = d;
    }
    final rawName = (best.className ?? '').trim();
    final bestName = rawName.isEmpty ? 'unknown' : rawName;
    final conf = (best.score ?? 0.0).clamp(0.0, 1.0);

    final bestNorm = bestName.toLowerCase();
    final selectedNorm = selected.toLowerCase();

    final matches = (bestNorm == selectedNorm) && (conf >= identifierConfidenceThreshold);
    return IdentDecision(bestName: bestName, bestConfidence: conf, matchesSelected: matches);
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

    // tolerant conflict test
    final bool authPresent = (authSum >= kConflictSumMin) || authHasStrong;
    final bool fakePresent = (fakeSum >= kConflictSumMin) || fakeHasStrong;

    if (authPresent && fakePresent) {
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

    return AnalysisResult(
      avgAuthenticScore: avgAuth,
      avgCounterfeitScore: avgFake,
      frontAuthenticScore: f.authScore,
      backAuthenticScore:  b.authScore,
      finalLabel: label,
    );
  }
}
