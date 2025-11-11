import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image/image.dart' as img;
import 'package:image/src/font/arial_14.dart';
import 'package:image/src/font/arial_24.dart';
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
      showHomeButton: true,
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
    bool isInconclusive = false;

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
        // Short summary, centered horizontally but aligned left within its own width
        statusDescription =
        'We couldn’t confidently determine the authenticity.\n'
            'Tap below to view possible reasons.';
        isInconclusive = true;
        break;
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
        crossAxisAlignment: CrossAxisAlignment.center,
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

          // Status Description (left-aligned)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Align(
              alignment: Alignment.center, // Centers the whole block
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 300,
                ),
                child: Text(
                  statusDescription,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.black87,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.left,
                ),
              ),
            ),
          ),

          // Expandable list only for Inconclusive
          if (isInconclusive) ...[
            const SizedBox(height: 8),
            const _InconclusiveReasons(),
          ],
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
          // Front and Back Images - Small size side by side
          Row(
            children: [
              // Front Image
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: const Color(0xFF4285F4).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: widget.frontImage != null
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
              // Back Image (if available)
              if (widget.backImage != null) ...[
                const SizedBox(width: 8),
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: const Color(0xFF4285F4).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      widget.backImage!,
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ],
            ],
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
                  'Scanned: ${_formatDateTime(DateTime.now())}',
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final month = dateTime.month.toString().padLeft(2, '0');
    final day = dateTime.day.toString().padLeft(2, '0');
    final year = dateTime.year;
    
    // Format time in 12-hour format
    int hour = dateTime.hour;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'pm' : 'am';
    
    if (hour == 0) {
      hour = 12;
    } else if (hour > 12) {
      hour -= 12;
    }
    
    return '$year-$month-$day $hour:$minute$period';
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
        return 'Save Result';
      default:
        return 'Save Result';
    }
  }

  void _handlePrimaryAction() {
    switch (widget.result.toLowerCase()) {
      case 'authentic':
        _showSaveDialog();
        break;
      case 'counterfeit':
        _showSaveDialog();
        break;
      default:
        _showSaveDialog();
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
              onPressed: () async {
                Navigator.of(context).pop();
                await _saveResult();
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _saveResult() async {
    try {
      // Create the report image
      final reportImage = await _createReportImage();
      if (reportImage == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to create report image'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Save to Pictures/SafeMed folder
      final saved = await _saveImageToDocuments(reportImage);
      if (saved) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Report saved successfully! Check Pictures/SafeMed folder in Gallery.'),
              backgroundColor: Color(0xFF4CAF50),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to save report'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save result: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<Uint8List?> _createReportImage() async {
    try {
      // Load front and back images
      final frontBytes = widget.frontImage?.readAsBytes();
      final backBytes = widget.backImage?.readAsBytes();
      
      if (frontBytes == null || backBytes == null) {
        return null;
      }

      final frontImage = img.decodeImage(await frontBytes);
      final backImage = img.decodeImage(await backBytes);
      
      if (frontImage == null || backImage == null) {
        return null;
      }

      // Resize images to same height (360px) while maintaining aspect ratio
      const targetHeight = 360;
      final frontResized = img.copyResize(frontImage, height: targetHeight);
      final backResized = img.copyResize(backImage, height: targetHeight);

      // Layout constants
      const padding = 24;
      const gap = 24;
      const headerHeight = 80;
      const footerHeight = 32;

      // Create report canvas (width: sum of images + gap + paddings)
      final canvasWidth = padding + frontResized.width + gap + backResized.width + padding;
      final canvasHeight = headerHeight + targetHeight + footerHeight + padding;
      
      // Create white background
      final reportImage = img.Image(width: canvasWidth, height: canvasHeight);
      img.fill(reportImage, color: img.ColorRgb8(255, 255, 255));

      // Header: Result line and subline
      final percent = (widget.confidenceScore * 100).toInt();
      final resultLine = '${_getResultText()}  $percent%';
      _drawText(reportImage, resultLine, x: padding, y: padding, size: 24, color: _getResultColor());
      _drawText(reportImage, 'Medicine: ${widget.selectedMedicine ?? 'Unknown'}', x: padding, y: padding + 32, size: 16, color: 0xFF4285F4);
      _drawText(reportImage, 'Date: ${DateTime.now().toString().split(' ')[0]}', x: padding, y: padding + 54, size: 14, color: 0xFF666666);

      // Add images side by side
      final imageY = headerHeight;
      final frontX = padding;
      final backX = padding + frontResized.width + gap;
      
      img.compositeImage(reportImage, frontResized, dstX: frontX, dstY: imageY);
      img.compositeImage(reportImage, backResized, dstX: backX, dstY: imageY);

      // Add labels
      _drawText(reportImage, 'Front View', x: frontX, y: imageY + targetHeight + 8, size: 14, color: 0xFF666666);
      _drawText(reportImage, 'Back View', x: backX, y: imageY + targetHeight + 8, size: 14, color: 0xFF666666);

      // Add footer
      _drawText(reportImage, 'Generated by SafeMed', x: padding, y: canvasHeight - footerHeight, size: 12, color: 0xFF999999);

      return Uint8List.fromList(img.encodePng(reportImage));
    } catch (e) {
      print('Error creating report image: $e');
      return null;
    }
  }

  void _drawText(img.Image image, String text, {required int x, required int y, required int size, required int color}) {
    final font = size >= 24 ? arial24 : arial14;
    img.drawString(
      image,
      text,
      x: x,
      y: y,
      font: font,
      color: img.ColorRgb8(
        (color >> 16) & 0xFF,
        (color >> 8) & 0xFF,
        color & 0xFF,
      ),
    );
  }

  String _getResultText() {
    switch (widget.result.toLowerCase()) {
      case 'authentic':
        return 'AUTHENTIC MEDICINE';
      case 'counterfeit':
        return 'COUNTERFEIT ALERT';
      default:
        return 'INCONCLUSIVE RESULT';
    }
  }

  int _getResultColor() {
    switch (widget.result.toLowerCase()) {
      case 'authentic':
        return 0xFF4CAF50; // Green
      case 'counterfeit':
        return 0xFFFF5252; // Red
      default:
        return 0xFFFF9800; // Orange
    }
  }

  Future<bool> _saveImageToDocuments(Uint8List imageBytes) async {
    try {
      // Get the external storage directory and navigate to public Pictures
      final externalDir = await getExternalStorageDirectory();
      if (externalDir == null) {
        print('External storage not available');
        return false;
      }

      // Construct the public Pictures path
      // externalDir.path is like /storage/emulated/0/Android/data/com.example.safemed/files
      // We need to go to /storage/emulated/0/Pictures/SafeMed
      final storageRoot = externalDir.path.split('/Android/data/')[0];
      final safeMedPath = '$storageRoot/Pictures/SafeMed';
      final safeMedDir = Directory(safeMedPath);
      
      // Create directory if it doesn't exist
      if (!await safeMedDir.exists()) {
        await safeMedDir.create(recursive: true);
      }

      // Generate filename with timestamp
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'safemed_report_$timestamp.png';
      final file = File('${safeMedDir.path}/$fileName');
      
      // Save the image
      await file.writeAsBytes(imageBytes);
      
      print('Report saved to: ${file.path}');
      return true;
    } catch (e) {
      print('Error saving image: $e');
      return false;
    }
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

class _InconclusiveReasons extends StatefulWidget {
  const _InconclusiveReasons();

  @override
  State<_InconclusiveReasons> createState() => _InconclusiveReasonsState();
}

class _InconclusiveReasonsState extends State<_InconclusiveReasons> {
  bool _expanded = false;

  final List<String> _reasons = const [
    'The uploaded photos are unclear or blurry.',
    'There is glare, reflections, or poor lighting.',
    'The packaging is partially obstructed or cropped.',
    'The uploaded medicine may not match the selected type.',
    'Multiple medicines may be visible in one image.',
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Toggle row
        InkWell(
          onTap: () => setState(() => _expanded = !_expanded),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Icon(
                _expanded ? Icons.expand_less : Icons.expand_more,
                color: const Color(0xFF4285F4),
              ),
              const SizedBox(width: 4),
              const Text(
                'Possible reasons',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF4285F4),
                ),
              ),
            ],
          ),
        ),

        // Collapsible content
        AnimatedCrossFade(
          crossFadeState: _expanded
              ? CrossFadeState.showFirst
              : CrossFadeState.showSecond,
          duration: const Duration(milliseconds: 200),
          firstChild: Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.only(left: 28.0, top: 6.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: _reasons.map((r) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('• ', style: TextStyle(fontSize: 14)),
                        Expanded(
                          child: Text(
                            r,
                            textAlign: TextAlign.left,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.black87,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          secondChild: const SizedBox.shrink(),
        ),
      ],
    );
  }
}
