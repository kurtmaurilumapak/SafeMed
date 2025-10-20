import 'package:flutter/material.dart';
import 'package:safemed/widgets/base_layout.dart';
import 'upload_screen.dart';
import '../services/pytorch_lite_service.dart';

class VerifyScreen extends StatefulWidget {
  const VerifyScreen({super.key});

  @override
  State<VerifyScreen> createState() => _VerifyScreenState();
}

class _VerifyScreenState extends State<VerifyScreen> {
  String? _selectedMedicine;

  final List<Map<String, dynamic>> medicines = [
    {
      'name': 'Biogesic',
      'image': 'assets/biogesic.png',
      'color': const Color(0xFF4285F4),
    },
    {
      'name': 'Alaxan',
      'image': 'assets/alaxan.png',
      'color': const Color(0xFFFF6B35),
    },
    {
      'name': 'Neozep',
      'image': 'assets/neozep.png',
      'color': const Color(0xFF4CAF50),
    },
    {
      'name': 'Medicol',
      'image': 'assets/medicol.png',
      'color': const Color(0xFF607D8B),
    },
    {
      'name': 'Bioflu',
      'image': 'assets/bioflu.png',
      'color': const Color(0xFF00BCD4),
    },
  ];

  @override
  Widget build(BuildContext context) {
    return BaseLayout(
      currentNavIndex: 1, // Set to Verify tab
      title: 'Upload Drug Images',
      showBackButton: true, // Show back button instead of logo
      padding: const EdgeInsets.all(24),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Select Medicine Title
                  const Text(
                    'Select Medicine',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Medicine Grid
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 2.5,
                    ),
                    itemCount: medicines.length,
                    itemBuilder: (context, index) {
                      final medicine = medicines[index];
                      final isSelected = _selectedMedicine == medicine['name'];

                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedMedicine = medicine['name'];
                          });
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color:
                                  isSelected
                                      ? const Color(0xFF4285F4)
                                      : Colors.transparent,
                              width: 2,
                            ),
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
                              const SizedBox(width: 12),
                              // Medicine Image
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: medicine['color'].withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(24),
                                  child: Image.asset(
                                    medicine['image'],
                                    width: 48,
                                    height: 48,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Icon(
                                        Icons.medication,
                                        color: medicine['color'],
                                        size: 24,
                                      );
                                    },
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              // Medicine Name
                              Expanded(
                                child: Text(
                                  medicine['name'],
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color:
                                        isSelected
                                            ? const Color(0xFF4285F4)
                                            : Colors.black,
                                  ),
                                ),
                              ),
                              // Selection Indicator
                              if (isSelected)
                                Container(
                                  width: 20,
                                  height: 20,
                                  margin: const EdgeInsets.only(right: 12),
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF4285F4),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.check,
                                    color: Colors.white,
                                    size: 14,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          // Proceed Button - Fixed at bottom
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: () async {
                if (_selectedMedicine == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please select a medicine')),
                  );
                  return;
                }
                await _showPreUploadReminder(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(
                  0xFF4285F4,
                ).withOpacity(_selectedMedicine != null ? 1.0 : 0.5),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                disabledBackgroundColor: const Color(
                  0xFF4285F4,
                ).withOpacity(0.3),
              ),
              child: const Text(
                'Proceed',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSafetyTip(IconData icon, String text, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black87,
                height: 1.4,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _showPreUploadReminder(BuildContext context) async {
    bool isLoading = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder:
              (ctx, setLocalState) => AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                title: Center(
                  child: Text(
                    'A Reminder Before You Proceed',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    SizedBox(height: 4),
                    Text(
                      '• Upload the exact medicine you selected to avoid errors.',
                    ),
                    SizedBox(height: 6),
                    Text('• Ensure photos are clear, well-lit, and in focus.'),
                    SizedBox(height: 6),
                    Text('• Do NOT include multiple medicines in one image.'),
                  ],
                ),
                actionsAlignment: MainAxisAlignment.center,
                actions: [
                  TextButton(
                    onPressed: isLoading ? null : () => Navigator.of(ctx).pop(),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed:
                        isLoading
                            ? null
                            : () async {
                              if (_selectedMedicine == null) return;
                              setLocalState(() => isLoading = true);
                              try {
                                await ModelService().preload(
                                  _selectedMedicine!,
                                ); // load the model here
                              } catch (e) {
                                setLocalState(() => isLoading = false);
                                if (!mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Failed to load model: $e'),
                                  ),
                                );
                                return;
                              }

                              if (!mounted) return;
                              Navigator.of(ctx).pop(); // close dialog
                              Navigator.push(
                                context,
                                PageRouteBuilder(
                                  pageBuilder: (context, animation, secondaryAnimation) => UploadScreen(
                                    selectedMedicine: _selectedMedicine!,
                                  ),
                                  transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                    // Slide in from right when entering
                                    const begin = Offset(1.0, 0.0);
                                    const end = Offset.zero;
                                    const curve = Curves.easeOutCubic;

                                    var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
                                    var offsetAnimation = animation.drive(tween);

                                    return SlideTransition(
                                      position: offsetAnimation,
                                      child: child,
                                    );
                                  },
                                  transitionDuration: const Duration(milliseconds: 300),
                                  reverseTransitionDuration: const Duration(milliseconds: 300),
                                ),
                              );
                            },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4285F4),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child:
                        isLoading
                            ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                            : const Text('Proceed'),
                  ),
                ],
              ),
        );
      },
    );
  }
}
