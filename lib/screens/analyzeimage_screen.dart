import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:math';
import '../widgets/base_layout.dart';
import 'results_screen.dart';

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
  late AnimationController _progressAnimationController;
  late Animation<double> _scanAnimation;
  late Animation<double> _progressAnimation;

  double _progress = 0.0;
  bool _analysisComplete = false;
  String _currentStep = "Analyzing images...";

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

    // Initialize progress animation
    _progressAnimationController = AnimationController(
      duration: const Duration(seconds: 5),
      vsync: this,
    );
    _progressAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _progressAnimationController,
        curve: Curves.easeOut,
      ),
    );

    // Start animations and simulation
    _startAnalysis();
  }

  void _startAnalysis() {
    // Start the scanning animation
    _scanAnimationController.repeat();

    // Start progress animation
    _progressAnimationController.forward();

    // Listen to progress changes
    _progressAnimationController.addListener(() {
      setState(() {
        _progress = _progressAnimation.value;

        // Update step text based on progress
        if (_progress < 0.3) {
          _currentStep = "Analyzing images...";
        } else if (_progress < 0.6) {
          _currentStep = "Scanning for authenticity markers...";
        } else if (_progress < 0.9) {
          _currentStep = "Verifying medicine details...";
        } else {
          _currentStep = "Finalizing analysis...";
        }
      });
    });

    // Complete analysis after animation
    _progressAnimationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          _analysisComplete = true;
          _currentStep = "Analysis complete!";
        });
        _scanAnimationController.stop();
      }
    });
  }

  @override
  void dispose() {
    _scanAnimationController.dispose();
    _progressAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BaseLayout(
      title: 'Verifying Medicine',
      currentNavIndex: 1,
      showBackButton: true,
      padding: const EdgeInsets.all(24),
      body: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight:
                MediaQuery.of(context).size.height -
                200, // Account for AppBar and BottomNav
          ),
          child: Column(
            children: [
              Expanded(
                flex: 0, // Don't force expansion
                child: Column(
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
                      'Analyzing images...',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),

                    const SizedBox(height: 8),

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
              ),

              const SizedBox(height: 24),

              // View Results Button (shown when analysis is complete)
              if (_analysisComplete)
                Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _handleViewResults,
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
    );
  }

  void _handleViewResults() {
    // Simulate different results for demo purposes
    final Random random = Random();
    final results = ['authentic', 'counterfeit', 'inconclusive'];
    final selectedResult = results[random.nextInt(results.length)];

    // Generate random confidence score based on result
    double confidenceScore;
    List<String>? warningSigns;

    switch (selectedResult) {
      case 'authentic':
        confidenceScore = 0.85 + random.nextDouble() * 0.15; // 85-100%
        warningSigns = null;
        break;
      case 'counterfeit':
        confidenceScore = 0.70 + random.nextDouble() * 0.25; // 70-95%
        warningSigns = [
          'Invalid serial number format',
          'Appears brighter or paler than usual',
          'Bigger cavity and more space',
          'Packaging inconsistencies detected',
        ];
        break;
      default: // inconclusive
        confidenceScore = 0.40 + random.nextDouble() * 0.35; // 40-75%
        warningSigns = [
          'Image quality too low for accurate analysis',
          'Partial packaging visible',
        ];
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => ResultsScreen(
              frontImage: widget.frontImage,
              backImage: widget.backImage,
              selectedMedicine: widget.selectedMedicine,
              result: selectedResult,
              confidenceScore: confidenceScore,
              warningSigns: warningSigns,
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
