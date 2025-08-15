import 'package:flutter/material.dart';

class BaseLayout extends StatefulWidget {
  final Widget body;
  final String? title;
  final bool showBackButton;
  final List<Widget>? actions;
  final int currentNavIndex;
  final bool showBottomNav;
  final Color? backgroundColor;
  final EdgeInsetsGeometry? padding;

  const BaseLayout({
    super.key,
    required this.body,
    this.title,
    this.showBackButton = false,
    this.actions,
    this.currentNavIndex = 0,
    this.showBottomNav = true,
    this.backgroundColor,
    this.padding,
  });

  @override
  State<BaseLayout> createState() => _BaseLayoutState();
}

class _BaseLayoutState extends State<BaseLayout> with TickerProviderStateMixin {
  int _selectedIndex = 0;
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.currentNavIndex;
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();
  }

  @override
  void didUpdateWidget(BaseLayout oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentNavIndex != widget.currentNavIndex) {
      setState(() {
        _selectedIndex = widget.currentNavIndex;
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: widget.backgroundColor ?? const Color(0xFFF8F9FA),
      appBar: _buildAppBar(),
      body:
          widget.padding != null
              ? Padding(padding: widget.padding!, child: widget.body)
              : widget.body,
      bottomNavigationBar:
          widget.showBottomNav ? _buildBottomNavigation() : null,
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      automaticallyImplyLeading: false,
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFFFFFF), Color(0xFFF8F9FA)],
          ),
          boxShadow: [
            BoxShadow(
              color: Color(0x0D000000),
              blurRadius: 12,
              spreadRadius: 0,
              offset: Offset(0, 2),
            ),
          ],
        ),
      ),
      leading:
          widget.showBackButton
              ? Container(
                margin: const EdgeInsets.only(left: 16, top: 8, bottom: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF4285F4).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  icon: const Icon(
                    Icons.arrow_back_ios_new,
                    color: Color(0xFF4285F4),
                    size: 20,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
              )
              : null,
      title: FadeTransition(
        opacity: _animation,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(-0.3, 0),
            end: Offset.zero,
          ).animate(_animation),
          child: Row(
            children: [
              Hero(
                tag: 'app_logo',
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF4285F4), Color(0xFF34A853)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF4285F4).withOpacity(0.3),
                        blurRadius: 8,
                        spreadRadius: 0,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.medical_services_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.title ?? 'SafeMed',
                    style: const TextStyle(
                      color: Color(0xFF1A1A1A),
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.5,
                    ),
                  ),
                  Text(
                    'Your Health Guardian',
                    style: TextStyle(
                      color: const Color(0xFF1A1A1A).withOpacity(0.6),
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions:
          widget.actions != null
              ? [
                ...widget.actions!.map(
                  (action) => Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: action,
                  ),
                ),
              ]
              : null,
    );
  }

  Widget _buildBottomNavigation() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            spreadRadius: 0,
            offset: const Offset(0, -4),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            spreadRadius: 0,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        child: Container(
          height: 80,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildNavItem(0, Icons.home_rounded, 'Home'),
              _buildNavItem(1, Icons.camera_alt_rounded, 'Verify'),
              _buildNavItem(2, Icons.info_outline_rounded, 'About'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _selectedIndex == index;

    return InkWell(
      onTap: () {
        if (_selectedIndex != index) {
          setState(() {
            _selectedIndex = index;
          });
          // Handle navigation based on index
          switch (index) {
            case 0:
              if (ModalRoute.of(context)?.settings.name != '/home') {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/home',
                  (route) => false,
                );
              }
              break;
            case 1:
              if (ModalRoute.of(context)?.settings.name != '/verify') {
                Navigator.pushReplacementNamed(context, '/verify');
              }
              break;
            case 2:
              if (ModalRoute.of(context)?.settings.name != '/about') {
                Navigator.pushReplacementNamed(context, '/about');
              }
              break;
          }
        }
      },
      splashColor: const Color(0xFF4285F4).withOpacity(0.1),
      highlightColor: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 80,
        height: 64,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color:
                    isSelected
                        ? const Color(0xFF4285F4).withOpacity(0.15)
                        : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                border:
                    isSelected
                        ? Border.all(
                          color: const Color(0xFF4285F4).withOpacity(0.2),
                          width: 1,
                        )
                        : null,
              ),
              child: AnimatedScale(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                scale: isSelected ? 1.1 : 1.0,
                child: Icon(
                  icon,
                  color:
                      isSelected
                          ? const Color(0xFF4285F4)
                          : const Color(0xFF9E9E9E),
                  size: 24,
                ),
              ),
            ),
            const SizedBox(height: 4),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              style: TextStyle(
                color:
                    isSelected
                        ? const Color(0xFF4285F4)
                        : const Color(0xFF9E9E9E),
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                letterSpacing: isSelected ? 0.2 : 0.0,
              ),
              child: Text(label),
            ),
          ],
        ),
      ),
    );
  }
}
