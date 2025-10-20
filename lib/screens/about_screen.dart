import 'package:flutter/material.dart';
import 'package:safemed/widgets/base_layout.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {

  @override
  Widget build(BuildContext context) {
    return BaseLayout(
      currentNavIndex: 2,
      title: 'About SafeMed',
      showBackButton: true, // Show back button instead of logo
      padding: const EdgeInsets.all(24),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // App Header Section
            _buildAppHeader(),

            const SizedBox(height: 32),

            // Mission Section
            _buildMissionSection(),

            const SizedBox(height: 32),

            // Key Features Section
            _buildFeaturesSection(),

            const SizedBox(height: 32),

            // Team Section
            _buildTeamSection(),

            const SizedBox(height: 32),

            // Technology Section
            _buildTechnologySection(),

            const SizedBox(height: 32),

            // Version & Legal
            _buildVersionSection(),

            const SizedBox(height: 100), // Extra space for bottom navigation
          ],
        ),
      ),
    );
  }

  Widget _buildAppHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF4285F4), Color(0xFF34A853)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4285F4).withOpacity(0.3),
            blurRadius: 20,
            spreadRadius: 0,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // App Logo
          Hero(
            tag: 'about_logo',
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    spreadRadius: 0,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.medical_services_rounded,
                color: Color(0xFF4285F4),
                size: 40,
              ),
            ),
          ),

          const SizedBox(height: 20),

          // App Name
          const Text(
            'SafeMed',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -1,
            ),
          ),

          const SizedBox(height: 8),

          // App Tagline
          const Text(
            'Your Health Guardian',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
          ),

          const SizedBox(height: 16),

          // Version Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.3)),
            ),
            child: const Text(
              'Version 1.0.0',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMissionSection() {
    return _buildSection(
      title: 'About Our App',
      icon: Icons.flag_rounded,
      iconColor: const Color(0xFF4285F4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Our app helps you stay safe by checking if your medicines are genuine. With just a quick scan, you can verify your medication’s authenticity and avoid counterfeit products, giving you peace of mind every time you take your medicine.',
            style: TextStyle(fontSize: 16, color: Colors.black87, height: 1.6),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildMissionPoint('🛡️', 'Protect Health'),
              const SizedBox(width: 16),
              _buildMissionPoint('🔍', 'Verify Authenticity'),
              const SizedBox(width: 16),
              _buildMissionPoint('📱', 'Easy to Use'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMissionPoint(String emoji, String text) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF4285F4).withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF4285F4).withOpacity(0.1)),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(height: 8),
            Text(
              text,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF4285F4),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturesSection() {
    final features = [
      {
        'icon': Icons.camera_alt_rounded,
        'title': 'Image Verification',
        'description':
            'Quick medicine verification through image upload and advanced AI analysis',
        'color': const Color(0xFF4285F4),
      },
      {
        'icon': Icons.security_rounded,
        'title': 'Authenticity Detection',
        'description':
            'Advanced algorithms detect counterfeit medicines with high accuracy',
        'color': const Color(0xFF34A853),
      },
      {
        'icon': Icons.verified_user_rounded,
        'title': 'Safety First',
        'description':
            'Comprehensive safety information and guidance for each verification',
        'color': const Color(0xFF9C27B0),
      },
    ];

    return _buildSection(
      title: 'Key Features',
      icon: Icons.star_rounded,
      iconColor: const Color(0xFF34A853),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 0.7, // Changed from 0.85 to 0.7 for more height
        ),
        itemCount: features.length,
        itemBuilder: (context, index) {
          final feature = features[index];
          return Container(
            padding: const EdgeInsets.all(16), // Reduced from 20 to 16
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: (feature['color'] as Color).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    feature['icon'] as IconData,
                    color: feature['color'] as Color,
                    size: 24,
                  ),
                ),
                const SizedBox(height: 12), // Reduced from 16 to 12
                Text(
                  feature['title'] as String,
                  style: const TextStyle(
                    fontSize: 15, // Reduced from 16 to 15
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 6), // Reduced from 8 to 6
                Expanded(
                  // Added Expanded to prevent overflow
                  child: Text(
                    feature['description'] as String,
                    style: TextStyle(
                      fontSize: 12, // Reduced from 13 to 12
                      color: Colors.grey.shade600,
                      height: 1.3, // Reduced line height from 1.4 to 1.3
                    ),
                    maxLines: 3, // Added max lines to prevent overflow
                    overflow:
                        TextOverflow.ellipsis, // Added ellipsis for long text
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatCard(String value, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTeamSection() {
    final teamMembers = [
      {
        'name': 'Brian Inguito',
        'role': 'Lead Researcher,\nUX/UI Designer',
        'avatar': '👨‍💻',
        'color': const Color(0xFF4285F4),
      },
      {
        'name': 'Kurt Mauri Lumapak',
        'role': 'Tech Lead,\nLead Developer',
        'avatar': '👨‍🔬',
        'color': const Color(0xFF34A853),
      },
    ];

    return _buildSection(
      title: 'Our Team',
      icon: Icons.group_rounded,
      iconColor: const Color(0xFF9C27B0),
      child: Column(
        children:
            teamMembers.map((member) {
              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(20),
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
                child: Row(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: (member['color'] as Color).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Center(
                        child: Text(
                          member['avatar'] as String,
                          style: const TextStyle(fontSize: 28),
                        ),
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            member['name'] as String,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            member['role'] as String,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: member['color'] as Color,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
      ),
    );
  }

  Widget _buildTechnologySection() {
    return _buildSection(
      title: 'Technology Stack',
      icon: Icons.code_rounded,
      iconColor: const Color(0xFFFF9800),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          _buildTechChip('Flutter', const Color(0xFF027DFD)),
          _buildTechChip('Dart', const Color(0xFF0175C2)),
          _buildTechChip('Machine Learning', const Color(0xFF4CAF50)),
          _buildTechChip('Computer Vision', const Color(0xFF9C27B0)),
          _buildTechChip('Roboflow', const Color(0xFFFF9800)),
          _buildTechChip('TensorFlow', const Color(0xFFFF6F00)),
        ],
      ),
    );
  }

  Widget _buildTechChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _buildContactItem(
    IconData icon,
    String title,
    String subtitle,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: Colors.grey.shade400,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVersionSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            'SafeMed v1.0.0',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '© 2024 SafeMed Team. All rights reserved.',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegalLink('Privacy Policy'),
              const SizedBox(width: 16),
              Text('•', style: TextStyle(color: Colors.grey.shade400)),
              const SizedBox(width: 16),
              _buildLegalLink('Terms of Service'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegalLink(String text) {
    return InkWell(
      onTap: () => _showLegalDialog(text),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: Color(0xFF4285F4),
          decoration: TextDecoration.underline,
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required Color iconColor,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: iconColor, size: 18),
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        child,
      ],
    );
  }

  void _showContactDialog(String type, String value) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Contact via $type'),
          content: Text('$type: $value'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Opening $type...'),
                    backgroundColor: const Color(0xFF4CAF50),
                  ),
                );
              },
              child: const Text('Open'),
            ),
          ],
        );
      },
    );
  }

  void _showLegalDialog(String title) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text('$title content would be displayed here.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }
}
