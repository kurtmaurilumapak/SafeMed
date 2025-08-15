import 'package:flutter/material.dart';
import 'dart:io';
import '../widgets/base_layout.dart';

class ResultsScreen extends StatefulWidget {
  final File? frontImage;
  final File? backImage;
  final String? selectedMedicine;
  final String result; // 'authentic', 'counterfeit', or 'inconclusive'
  final double confidenceScore;
  final List<String>? warningSigns;

  const ResultsScreen({
    super.key,
    this.frontImage,
    this.backImage,
    this.selectedMedicine,
    required this.result,
    required this.confidenceScore,
    this.warningSigns,
  });

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeAnimationController;
  late AnimationController _scaleAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _fadeAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _scaleAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _fadeAnimationController, curve: Curves.easeOut),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _scaleAnimationController,
        curve: Curves.elasticOut,
      ),
    );

    // Start animations
    _fadeAnimationController.forward();
    Future.delayed(const Duration(milliseconds: 200), () {
      _scaleAnimationController.forward();
    });
  }

  @override
  void dispose() {
    _fadeAnimationController.dispose();
    _scaleAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BaseLayout(
      title: 'Verification Result',
      currentNavIndex: 1,
      showBackButton: true,
      padding: const EdgeInsets.all(24),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Result Header
              ScaleTransition(
                scale: _scaleAnimation,
                child: _buildResultHeader(),
              ),

              const SizedBox(height: 32),

              // Confidence Score
              _buildConfidenceScore(),

              const SizedBox(height: 24),

              // Medicine Information
              _buildMedicineInfo(),

              if (widget.warningSigns != null &&
                  widget.warningSigns!.isNotEmpty) ...[
                const SizedBox(height: 24),
                _buildWarningSection(),
              ],

              const SizedBox(height: 32),

              // Action Buttons
              _buildActionButtons(),

              const SizedBox(height: 24),

              // Safety Information
              _buildSafetyInformation(),

              const SizedBox(height: 100), // Extra space for bottom navigation
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultHeader() {
    Color statusColor;
    IconData statusIcon;
    String statusTitle;
    String statusDescription;

    switch (widget.result.toLowerCase()) {
      case 'authentic':
        statusColor = const Color(0xFF4CAF50);
        statusIcon = Icons.verified_user;
        statusTitle = 'Authentic Medicine';
        statusDescription =
            'This medicine appears to be genuine based on our analysis';
        break;
      case 'counterfeit':
        statusColor = const Color(0xFFFF5252);
        statusIcon = Icons.warning;
        statusTitle = 'Counterfeit Alert';
        statusDescription =
            'This medicine appears to be counterfeit based on our analysis';
        break;
      default:
        statusColor = const Color(0xFFFF9800);
        statusIcon = Icons.help_outline;
        statusTitle = 'Inconclusive Result';
        statusDescription =
            'Unable to determine authenticity. Please consult a pharmacist';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            spreadRadius: 0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Status Icon
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(statusIcon, color: statusColor, size: 40),
          ),

          const SizedBox(height: 16),

          // Status Title
          Text(
            statusTitle,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: statusColor,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 8),

          // Status Description
          Text(
            statusDescription,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.black87,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildConfidenceScore() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            spreadRadius: 0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${(widget.confidenceScore * 100).toInt()}% ${_getConfidenceText()}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              Text(
                '${(widget.confidenceScore * 100).toInt()}%',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF4285F4),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Progress Bar
          Container(
            width: double.infinity,
            height: 8,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(4),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: widget.confidenceScore,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: _getConfidenceColors(),
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMedicineInfo() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            spreadRadius: 0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Medicine Image or Icon
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: const Color(0xFF4285F4).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child:
                widget.frontImage != null
                    ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        widget.frontImage!,
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                      ),
                    )
                    : const Icon(
                      Icons.medication,
                      color: Color(0xFF4285F4),
                      size: 30,
                    ),
          ),

          const SizedBox(width: 16),

          // Medicine Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.selectedMedicine ?? 'Unknown Medicine',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Scanned: ${DateTime.now().toString().split(' ')[0]}',
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWarningSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFF9800).withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            spreadRadius: 0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: const Color(0xFFFF9800),
                size: 24,
              ),
              const SizedBox(width: 8),
              const Text(
                'Warning Signs Detected',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          ...widget.warningSigns!.map(
            (warning) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    margin: const EdgeInsets.only(top: 2),
                    decoration: const BoxDecoration(
                      color: Color(0xFFFF9800),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 12,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      warning,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.black87,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        // Primary Action Button
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _handlePrimaryAction,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4285F4),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              _getPrimaryActionText(),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Secondary Action Button
        SizedBox(
          width: double.infinity,
          height: 56,
          child: OutlinedButton(
            onPressed: _handleSecondaryAction,
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF4285F4),
              side: const BorderSide(color: Color(0xFF4285F4)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Scan Another Medicine',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSafetyInformation() {
    List<Map<String, dynamic>> safetyTips;

    switch (widget.result.toLowerCase()) {
      case 'authentic':
        safetyTips = [
          {
            'icon': Icons.check_circle_outline,
            'text': 'Medicine appears genuine - safe to use as prescribed',
            'color': const Color(0xFF4CAF50),
          },
          {
            'icon': Icons.schedule,
            'text': 'Always check expiration date before use',
            'color': const Color(0xFF4285F4),
          },
        ];
        break;
      case 'counterfeit':
        safetyTips = [
          {
            'icon': Icons.dangerous,
            'text': 'Do not use this medicine - it may be harmful',
            'color': const Color(0xFFFF5252),
          },
          {
            'icon': Icons.local_hospital,
            'text': 'Consult a healthcare professional immediately',
            'color': const Color(0xFFFF5252),
          },
          {
            'icon': Icons.report,
            'text': 'Report to local health authorities',
            'color': const Color(0xFFFF9800),
          },
        ];
        break;
      default:
        safetyTips = [
          {
            'icon': Icons.help_outline,
            'text': 'Verify with a licensed pharmacist before use',
            'color': const Color(0xFFFF9800),
          },
          {
            'icon': Icons.store,
            'text': 'Purchase only from authorized retailers',
            'color': const Color(0xFF4285F4),
          },
        ];
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            spreadRadius: 0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Safety Information',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),

          const SizedBox(height: 16),

          ...safetyTips.map(
            (tip) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: tip['color'].withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(tip['icon'], color: tip['color'], size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      tip['text'],
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.black87,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getConfidenceText() {
    switch (widget.result.toLowerCase()) {
      case 'authentic':
        return 'Match with Authentic';
      case 'counterfeit':
        return 'Match with Counterfeit';
      default:
        return 'Confidence Level';
    }
  }

  List<Color> _getConfidenceColors() {
    switch (widget.result.toLowerCase()) {
      case 'authentic':
        return [const Color(0xFF4CAF50), const Color(0xFF8BC34A)];
      case 'counterfeit':
        return [const Color(0xFFFF5252), const Color(0xFFFF7043)];
      default:
        return [const Color(0xFFFF9800), const Color(0xFFFFB74D)];
    }
  }

  String _getPrimaryActionText() {
    switch (widget.result.toLowerCase()) {
      case 'authentic':
        return 'Save Result';
      case 'counterfeit':
        return 'Report Counterfeit';
      default:
        return 'Get Help';
    }
  }

  void _handlePrimaryAction() {
    switch (widget.result.toLowerCase()) {
      case 'authentic':
        _showSaveDialog();
        break;
      case 'counterfeit':
        _showReportDialog();
        break;
      default:
        _showHelpDialog();
    }
  }

  void _handleSecondaryAction() {
    // Navigate back to verify screen
    Navigator.pushNamedAndRemoveUntil(
      context,
      '/verify',
      (route) => route.settings.name == '/home',
    );
  }

  void _showSaveDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Save Result'),
          content: const Text(
            'Would you like to save this verification result for future reference?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Result saved successfully'),
                    backgroundColor: Color(0xFF4CAF50),
                  ),
                );
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _showReportDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Report Counterfeit Medicine'),
          content: const Text(
            'This will report the counterfeit medicine to the appropriate health authorities. Continue?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Report submitted to authorities'),
                    backgroundColor: Color(0xFF4CAF50),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF5252),
              ),
              child: const Text('Report'),
            ),
          ],
        );
      },
    );
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Need Help?'),
          content: const Text(
            'Contact a licensed pharmacist or healthcare provider for assistance with medicine verification.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Could open contact info or help resources
              },
              child: const Text('Find Pharmacist'),
            ),
          ],
        );
      },
    );
  }
}
