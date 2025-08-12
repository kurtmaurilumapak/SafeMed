import 'package:flutter/material.dart';
import 'upload_screen.dart';

class VerifyScreen extends StatefulWidget {
  const VerifyScreen({super.key});

  @override
  State<VerifyScreen> createState() => _VerifyScreenState();
}

class _VerifyScreenState extends State<VerifyScreen> {
  int _selectedIndex = 1; // Set to Verify tab
  String? _selectedMedicine;

  final List<Map<String, dynamic>> medicines = [
    {
      'name': 'Biogesic',
      'image': 'assets/biogesic.png',
      'color': const Color(0xFF4285F4),
    },
    {
      'name': 'Decolgen',
      'image': 'assets/decolgen.png',
      'color': const Color(0xFFFF9800),
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
      'name': 'Diatabs',
      'image': 'assets/diatabs.png',
      'color': const Color(0xFF9E9E9E),
    },
    {
      'name': 'Solmux',
      'image': 'assets/solmux.png',
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
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Upload Drug Images',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
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

            const SizedBox(height: 32),

            // Warning Message
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF8E1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFFB74D), width: 1),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: const Color(0xFFFF8F00),
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Make sure the packaging is clear and well-lit.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFFE65100),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Proceed Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed:
                    _selectedMedicine != null
                        ? () {
                          // Handle proceed with selected medicine
                          _proceedWithVerification();
                        }
                        : null,
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

            const SizedBox(height: 32),

            // Safety Tips Section
            const Text(
              'Safety Tips',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 16),

            // Safety Tips List
            _buildSafetyTip(
              Icons.verified_user,
              'Always verify the security seal before use',
              const Color(0xFF4285F4),
            ),
            const SizedBox(height: 12),
            _buildSafetyTip(
              Icons.calendar_today,
              'Check expiration date and packaging integrity',
              const Color(0xFF4285F4),
            ),
            const SizedBox(height: 12),
            _buildSafetyTip(
              Icons.store,
              'Buy only from licensed pharmacies',
              const Color(0xFF4285F4),
            ),

            const SizedBox(height: 100), // Extra space for bottom navigation
          ],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              spreadRadius: 0,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) {
            setState(() {
              _selectedIndex = index;
            });
            // Handle navigation based on index
            switch (index) {
              case 0:
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/home',
                  (route) => false,
                );
                break;
              case 1:
                // Already on Verify screen
                break;
              case 2:
                Navigator.pushNamed(context, '/about');
                break;
            }
          },
          backgroundColor: Colors.white,
          selectedItemColor: const Color(0xFF4285F4),
          unselectedItemColor: Colors.grey,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
            BottomNavigationBarItem(
              icon: Icon(Icons.camera_alt),
              label: 'Verify',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.info_outline),
              label: 'About',
            ),
          ],
        ),
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

  void _proceedWithVerification() {
    // Navigate directly to upload screen with selected medicine
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UploadScreen(selectedMedicine: _selectedMedicine),
      ),
    );
  }
}
