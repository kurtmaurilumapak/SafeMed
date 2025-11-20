import 'package:flutter/material.dart';
import 'dart:io';
import 'results_screen.dart';
import '../services/pytorch_lite_service.dart';
import 'dart:async'; // for Timer

class AnalyzeImageScreen extends StatefulWidget {
  final File? frontImage;
  final File? backImage;
  final String? selectedMedicine;

  const AnalyzeImageScreen({
    super.key,
    this.frontImage,
    this.backImage,
    this.selectedMedicine,
  });

  @override
  State<AnalyzeImageScreen> createState() => _AnalyzeImageScreenState();
}

class _AnalyzeImageScreenState extends State<AnalyzeImageScreen>
    with TickerProviderStateMixin {
  late AnimationController _scanAnimationController;
  late Animation<double> _scanAnimation;

  double _progress = 0.0;
  bool _analysisComplete = false;
  String _currentStep = "Analyzing images...";
  Timer? _progressTicker;   // drives the progress bar while work runs
  bool _running = false;    // prevents double-starts
  AnalysisResult? _analysisResult;
  String _idLocation = '';

  @override
  void initState() {
    super.initState();

    // Initialize scan animation (rotating scanner)
    _scanAnimationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _scanAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _scanAnimationController, curve: Curves.linear),
    );
    _scanAnimationController.repeat();

    // Start real analysis immediately
    _runAnalysis();
  }

  void _startProgressTicker(double ceiling) {
    _progressTicker?.cancel();
    _progressTicker = Timer.periodic(const Duration(milliseconds: 120), (t) {
      if (!_running || !mounted) { t.cancel(); return; }
      setState(() {
        final next = _progress + 0.02;
        _progress = next > ceiling ? ceiling : next;
      });
    });
  }

  void _snapTo(double v) {
    if (!mounted) return;
    setState(() { _progress = v.clamp(0.0, 1.0); });
  }

  String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }

  Future<void> _runAnalysis() async {
    if (_running) return;
    if (widget.selectedMedicine == null || widget.frontImage == null || widget.backImage == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Missing medicine or images')),
      );
      Navigator.pop(context); // back to Upload screen
      return;
    }
    _running = true;

    try {
      // STEP 1: Identify medicine type (front + back) with tolerance
      setState(() { _currentStep = 'Identifying medicine type on IMAGE 1…'; });
      _startProgressTicker(0.20);
      await ModelService().preloadIdentifier();

      final selected = widget.selectedMedicine!;

      // Identify only the FRONT image first using top-1 decision like Roboflow preview
      _idLocation = 'FRONT';
      final frontDecision = await ModelService().identifySelected(widget.frontImage!, selected);
      if (!frontDecision.matchesSelected) {
        throw MedicineMismatchException(frontDecision.bestName, selected);
      }

      // Additionally verify the BACK image with the identifier before heavy analysis
      setState(() { _currentStep = 'Identifying medicine type on IMAGE 2…'; });
      _startProgressTicker(0.40);
      _idLocation = 'BACK';
      final backDecision = await ModelService().identifySelected(widget.backImage!, selected);
      if (!backDecision.matchesSelected) {
        throw MedicineMismatchException(backDecision.bestName, selected);
      }

      // STEP 2: Load/preload model
      setState(() { _currentStep = 'Loading model…'; });
      _startProgressTicker(0.50);
      // If you didn't preload on VerifyScreen, this ensures the model is ready:
      await ModelService().preload(widget.selectedMedicine!);

      // STEP 3: Detect on FRONT
      setState(() { _currentStep = 'Detecting on IMAGE 1…'; });
      _startProgressTicker(0.70);
      final front = await ModelService().scoreOne(
        medicine: widget.selectedMedicine!,
        image: widget.frontImage!,
        tag: 'front',
      );

      // STEP 4: Detect on BACK
      setState(() { _currentStep = 'Detecting on IMAGE 2…'; });
      _startProgressTicker(0.90);
      final back = await ModelService().scoreOne(
        medicine: widget.selectedMedicine!,
        image: widget.backImage!,
        tag: 'back',
      );

      // STEP 5: Compute averages & decision
      setState(() { _currentStep = 'Computing averages & decision…'; });
      _startProgressTicker(0.95);

      // Averages using the raw-sum capped evidence (as in your service)
      final avgAuth = ((front.authScore + back.authScore) / 2.0).clamp(0.0, 1.0);
      final avgFake = ((front.fakeScore + back.fakeScore) / 2.0).clamp(0.0, 1.0);

      String label;
      if (avgAuth >= ModelService.decisionThreshold) {
        label = 'authentic';
      } else if (avgFake >= ModelService.decisionThreshold) {
        label = 'counterfeit';
      } else {
        label = 'inconclusive';
      }

      // Build the same AnalysisResult you normally pass around
      final res = AnalysisResult(
        avgAuthenticScore: avgAuth,
        avgCounterfeitScore: avgFake,
        frontAuthenticScore: front.authScore,
        backAuthenticScore:  back.authScore,
        finalLabel: label,
      );

      // Finish up UI
      setState(() { _currentStep = 'Finalizing…'; });
      _startProgressTicker(0.98);
      await Future.delayed(const Duration(milliseconds: 250));
      _snapTo(1.0);

      setState(() {
        _analysisComplete = true;
        _currentStep = 'Done!';
      });
      _scanAnimationController.stop();
      _analysisResult = res; // cache for the button
    } on MultipleItemsDetectedException catch (e) {
      if (!mounted) return;

      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          title: const Text(
            'Multiple Medicines Detected',
            style: TextStyle(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          content: Text(
            'Multiple medicine packs detected in the ${e.location} image.\n\n'
                'Please retake clear photos showing only a single pack and try again.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text(
                'OK',
                style: TextStyle(color: Color(0xFF4285F4), fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      );

      if (mounted) Navigator.pop(context); // Back to Upload screen
    } on MedicineMismatchException catch (e) {
      if (!mounted) return;

      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          title: const Text(
            'Medicine Mismatch Detected',
            style: TextStyle(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          content: Text(
            'The system detected ${_capitalize(e.detectedMedicine)} in the ${_idLocation.isEmpty ? 'image' : _idLocation.toLowerCase()} image, but you selected ${e.selectedMedicine}.\n\n'
                'Please ensure you are analyzing the correct medicine and try again.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text(
                'OK',
                style: TextStyle(color: Color(0xFF4285F4), fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      );

      if (mounted) Navigator.pop(context); // Back to Upload screen
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Analysis failed: $e')),
      );
      Navigator.pop(context); // back to Upload screen
    } finally {
      _progressTicker?.cancel();
      _running = false;
    }
  }

  @override
  void dispose() {
    _progressTicker?.cancel();
    _scanAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight:
                MediaQuery.of(context).size.height -
                    200, // Account for SafeArea
              ),
              child: Column(
                children: [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Scanning Animation
                      Container(
                        width: 180,
                        height: 180,
                        child: AnimatedBuilder(
                          animation: _scanAnimation,
                          builder: (context, child) {
                            return Stack(
                              alignment: Alignment.center,
                              children: [
                                // Outer scanning circle
                                Container(
                                  width: 180,
                                  height: 180,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.grey.shade300,
                                      width: 2,
                                    ),
                                  ),
                                ),

                                // Animated scanning arcs
                                Transform.rotate(
                                  angle: _scanAnimation.value * 2 * 3.14159,
                                  child: Container(
                                    width: 160,
                                    height: 160,
                                    child: CustomPaint(
                                      painter: ScanningArcsPainter(),
                                    ),
                                  ),
                                ),

                                // Center medicine icon
                                Container(
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF4285F4),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.medical_services_rounded,
                                    color: Colors.white,
                                    size: 30,
                                  ),
                                ),

                                // Checkmark when complete
                                if (_analysisComplete)
                                  Positioned(
                                    bottom: 15,
                                    right: 15,
                                    child: Container(
                                      width: 28,
                                      height: 28,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF4285F4),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.check,
                                        color: Colors.white,
                                        size: 18,
                                      ),
                                    ),
                                  ),
                              ],
                            );
                          },
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Analysis Status
                      Text(
                        _analysisComplete ? 'Analyzing Complete!' : 'Analyzing Image',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),

                      const SizedBox(height: 8),

                      if (!_analysisComplete)
                        Text(
                          'Please wait while we scan your drug\nimages for authenticity. This might\ntake a few seconds.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                            height: 1.4,
                          ),
                        ),

                      const SizedBox(height: 32),

                      // Progress Bar
                      Container(
                        width: double.infinity,
                        height: 6,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: Row(
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              width:
                              (MediaQuery.of(context).size.width - 48) *
                                  _progress,
                              height: 6,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF4285F4), Color(0xFF1976D2)],
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                ),
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 8),

                      // Progress Text and Percentage
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Text(
                              _currentStep,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            '${(_progress * 100).toInt()}%',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF4285F4),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Tip Section
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF4285F4).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                color: const Color(0xFF4285F4),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.lightbulb_outline,
                                color: Colors.white,
                                size: 12,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Expanded(
                              child: Text(
                                'Tip: Keep your app open during analysis',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF4285F4),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // View Results Button (shown when analysis is complete)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 24),
                    child: SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _analysisComplete ? _handleViewResults : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4285F4),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'View Results',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _handleViewResults() {
    if (_analysisResult == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please wait for analysis to complete')),
      );
      return;
    }

    final res = _analysisResult!;
    final double displayScore = (res.finalLabel == 'counterfeit')
        ? res.avgCounterfeitScore
        : res.avgAuthenticScore;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ResultsScreen(
          selectedMedicine: widget.selectedMedicine,
          frontImage: widget.frontImage,
          backImage: widget.backImage,
          result: res.finalLabel,
          confidenceScore: displayScore,
          // frontScore: res.frontAuthenticScore,
          // backScore:  res.backAuthenticScore,
        ),
      ),
    );
  }
}

class ScanningArcsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint =
    Paint()
      ..color = const Color(0xFF4285F4)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Draw four scanning arcs
    for (int i = 0; i < 4; i++) {
      final startAngle = (i * 1.57) + 0.2; // 90 degrees apart + offset
      const sweepAngle = 1.0; // ~57 degrees

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}