import 'package:flutter/material.dart';

class BaseLayout extends StatefulWidget {
  final Widget body;
  final String? title;
  final bool showBackButton;
  final bool showHomeButton;
  final List<Widget>? actions;
  final int currentNavIndex;
  final Color? backgroundColor;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onBackPressed;

  const BaseLayout({
    super.key,
    required this.body,
    this.title,
    this.showBackButton = false,
    this.showHomeButton = false,
    this.actions,
    this.currentNavIndex = 0,
    this.backgroundColor,
    this.padding,
    this.onBackPressed,
  });

  @override
  State<BaseLayout> createState() => _BaseLayoutState();
}

class _BaseLayoutState extends State<BaseLayout> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
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
      bottomNavigationBar: null,
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
                  onPressed: widget.onBackPressed ?? () {
                    Navigator.pop(context);
                  },
                ),
              )
              : widget.showHomeButton
                  ? Container(
                    margin: const EdgeInsets.only(left: 16, top: 8, bottom: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4285F4).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.home_rounded,
                        color: Color(0xFF4285F4),
                        size: 20,
                      ),
                      onPressed: () {
                        Navigator.pushNamedAndRemoveUntil(
                          context,
                          '/home',
                          (route) => false,
                        );
                      },
                    ),
                  )
                  : null,
      title: (widget.showBackButton || widget.showHomeButton)
              ? Column(
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
                    // Only show "Your Health Guardian" on home screen
                    if (ModalRoute.of(context)?.settings.name == '/home')
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
                )
              : FadeTransition(
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
      actions: [
        if (widget.actions != null)
          ...widget.actions!.map(
            (action) => Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: action,
            ),
          ),
        // Add about icon to the right side (only if not on about screen and not showing home button)
        if (!widget.showBackButton && !widget.showHomeButton && ModalRoute.of(context)?.settings.name != '/about')
          Container(
            margin: const EdgeInsets.only(right: 16, top: 8, bottom: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF4285F4).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(
                Icons.info_outline_rounded,
                color: Color(0xFF4285F4),
                size: 20,
              ),
              onPressed: () {
                if (ModalRoute.of(context)?.settings.name != '/about') {
                  Navigator.pushNamed(context, '/about');
                }
              },
            ),
          ),
      ],
    );
  }

}
