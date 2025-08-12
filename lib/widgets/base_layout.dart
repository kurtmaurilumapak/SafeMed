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

class _BaseLayoutState extends State<BaseLayout> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.currentNavIndex;
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
      automaticallyImplyLeading: widget.showBackButton,
      leading:
          widget.showBackButton
              ? IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black),
                onPressed: () => Navigator.pop(context),
              )
              : null,
      title: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFF4285F4),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.medical_services_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            widget.title ?? 'SafeMed',
            style: const TextStyle(
              color: Colors.black,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
      actions: widget.actions,
    );
  }

  Widget _buildBottomNavigation() {
    return Container(
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
              if (ModalRoute.of(context)?.settings.name != '/') {
                Navigator.pushReplacementNamed(context, '/');
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
    );
  }
}
