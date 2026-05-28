import 'dart:async';
import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/cyber/glass_card.dart';
import '../../../widgets/cyber/cyber_widgets.dart';

class TechnicianDashboardScreen extends StatefulWidget {
  final ValueChanged<int>? onNavTap;

  const TechnicianDashboardScreen({super.key, this.onNavTap});

  @override
  State<TechnicianDashboardScreen> createState() => _TechnicianDashboardScreenState();
}

class _TechnicianDashboardScreenState extends State<TechnicianDashboardScreen>
    with TickerProviderStateMixin {
  int _timerSeconds = 899;
  late Timer _timer;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && _timerSeconds > 0) {
        setState(() => _timerSeconds--);
      }
    });
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();
    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _timer.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  String get _timerString {
    final m = _timerSeconds ~/ 60;
    final s = _timerSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      extendBody: true,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              // AppBar
              SliverAppBar(
                pinned: true,
                backgroundColor: AppColors.surface.withOpacity(0.7),
                flexibleSpace: _buildAppBar(),
                toolbarHeight: 64,
                elevation: 0,
                bottom: PreferredSize(
                  preferredSize: Size.zero,
                  child: Container(height: 1, color: Colors.white.withOpacity(0.1)),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 120),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _buildQuickStats(),
                    const SizedBox(height: 16),
                    _buildMapWidget(),
                    const SizedBox(height: 16),
                    _buildCurrentPriority(),
                    const SizedBox(height: 16),
                    _buildToolsGrid(),
                    const SizedBox(height: 16),
                    _buildPerformanceChart(),
                  ]),
                ),
              ),
            ],
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.assignment), label: 'Tickets'),
          BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Map'),
          BottomNavigationBarItem(icon: Icon(Icons.notifications), label: 'Notifications'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
        onTap: widget.onNavTap ?? (_) {},
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Stack(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.tertiary.withOpacity(0.3), width: 1),
                  image: const DecorationImage(
                    image: NetworkImage('https://lh3.googleusercontent.com/aida-public/AB6AXuA0TEUAs_uo1AKYnlx-EGcDCeAST3pH1fLxBpdcfNmjuollipf_WuUOuMzEQ3W5D2EjqCpNP5e_wHb7GKdq_1y9zJwo6o9LfYd723A3_kXNU4cdTlAanakoMUO6vQeezvwSuU6MgWmBq3w3KsrBcIX1v_fRMKElPL3XsaIgDK3F5eS9k0ydHmNhv4ja7-yLzk4qDuEtXJ5Gnh3GQER2JUwY8d6k1mJgxlxSR9WkP4rdGFAIS_iO5Ofguxc2eIYTe64IX2_um-P2aTA'),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (_, child) => Transform.scale(
                    scale: _pulseAnimation.value,
                    child: child,
                  ),
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: AppColors.tertiary,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.background, width: 2),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'TechPulse',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.tertiary,
                  letterSpacing: -0.5,
                ),
              ),
              const Text(
                'TECHNICIAN ONLINE',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  color: AppColors.tertiary,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: AppColors.onSurfaceVariant),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildStatCard('SLA HEALTH', '02:45:12', isCyan: true, icon: Icons.timer_outlined)),
            const SizedBox(width: 12),
            Expanded(child: _buildStatCard('ROUTE DIST.', '4.2 km', icon: Icons.route_outlined)),
          ],
        ),
        const SizedBox(height: 12),
        _buildStatCard('OPEN TASKS', '08 active', icon: Icons.checklist_outlined, fullWidth: true),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, {bool isCyan = false, IconData? icon, bool fullWidth = false}) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: AppColors.onSurfaceVariant,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: isCyan ? AppColors.tertiary : AppColors.onSurface,
                  shadows: isCyan
                      ? [Shadow(color: AppColors.tertiary.withOpacity(0.5), blurRadius: 10)]
                      : null,
                ),
              ),
            ],
          ),
          if (icon != null)
            Positioned(
              right: -10,
              bottom: -10,
              child: Icon(icon, size: 60, color: AppColors.onSurface.withOpacity(0.07)),
            ),
        ],
      ),
    );
  }

  Widget _buildMapWidget() {
    return GlassCard(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        height: 200,
        child: Stack(
          children: [
            // Dark map background
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Container(
                color: AppColors.surfaceContainerLow,
                child: CustomPaint(
                  painter: _MapGridPainter(),
                  child: Container(),
                ),
              ),
            ),
            // Gradient overlay
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.center,
                    radius: 0.9,
                    colors: [Colors.transparent, AppColors.background.withOpacity(0.7)],
                  ),
                ),
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Location chip
                  GlassCard(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    borderRadius: BorderRadius.circular(12),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.location_on_outlined, color: AppColors.tertiary, size: 18),
                        const SizedBox(width: 6),
                        const Text(
                          'Next: HQ Data Center',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppColors.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Navigate button
                  Align(
                    alignment: Alignment.centerRight,
                    child: _buildGradientButton(
                      icon: Icons.near_me,
                      label: 'START NAVIGATION',
                      onTap: () {},
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGradientButton({required IconData icon, required String label, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.secondaryContainer, AppColors.tertiary],
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: AppColors.tertiary.withOpacity(0.4),
              blurRadius: 15,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppColors.onPrimary, size: 16),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.onPrimary,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentPriority() {
    return Column(
      children: [
        Row(
          children: [
            Container(width: 4, height: 24, decoration: BoxDecoration(color: AppColors.tertiary, borderRadius: BorderRadius.circular(4))),
            const SizedBox(width: 8),
            const Text(
              'Current Priority',
              style: TextStyle(fontFamily: 'Inter', fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.onSurface),
            ),
            const Spacer(),
            Text(
              'ID: #INC-8840',
              style: TextStyle(fontFamily: 'Inter', fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.onSurfaceVariant),
            ),
          ],
        ),
        const SizedBox(height: 12),
        GlassCard(
          padding: const EdgeInsets.all(20),
          borderRadius: BorderRadius.circular(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _buildBadge('HIGH PRIORITY', AppColors.errorContainer, AppColors.error, glow: true),
                  const SizedBox(width: 8),
                  _buildBadge('HARDWARE FAULT', Colors.white.withOpacity(0.05), AppColors.onSurfaceVariant),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Server Node Failure - Sector 7G',
                          style: TextStyle(
                            fontFamily: 'Inter', fontSize: 20, fontWeight: FontWeight.w600,
                            color: AppColors.onSurface, height: 1.3,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'UPS critical battery warning in rack B-12. Immediate replacement required to prevent cascading shutdown.',
                          style: TextStyle(
                            fontFamily: 'Inter', fontSize: 14, color: AppColors.onSurfaceVariant, height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        'REMAINING TIME',
                        style: TextStyle(fontFamily: 'Inter', fontSize: 9, fontWeight: FontWeight.w600, color: AppColors.onSurfaceVariant, letterSpacing: 0.8),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _timerString,
                        style: TextStyle(
                          fontFamily: 'Inter', fontSize: 24, fontWeight: FontWeight.w600,
                          color: AppColors.error,
                          shadows: [Shadow(color: AppColors.error.withOpacity(0.5), blurRadius: 10)],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildOutlineButton(Icons.explore_outlined, 'NAVIGATE', () {}),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildOutlineButton(Icons.qr_code_scanner, 'SCAN ASSET', () {}),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBadge(String text, Color bg, Color fg, {bool glow = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
        boxShadow: glow ? [BoxShadow(color: AppColors.error.withOpacity(0.2), blurRadius: 10)] : null,
      ),
      child: Text(
        text,
        style: TextStyle(fontFamily: 'Inter', fontSize: 9, fontWeight: FontWeight.w600, color: fg, letterSpacing: 0.5),
      ),
    );
  }

  Widget _buildOutlineButton(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppColors.onSurface, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.onSurface, letterSpacing: 0.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToolsGrid() {
    final tools = [
      (Icons.fact_check_outlined, 'Repair Checklist'),
      (Icons.inventory_2_outlined, 'Asset History'),
      (Icons.chat_bubble_outline, 'Real-time Chat'),
      (Icons.camera_alt_outlined, 'Report Issue'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Field Operations Tools',
          style: TextStyle(fontFamily: 'Inter', fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.onSurface),
        ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 1.5,
          children: tools.map((t) => _buildToolCard(t.$1, t.$2)).toList(),
        ),
      ],
    );
  }

  Widget _buildToolCard(IconData icon, String label) {
    return GlassCard(
      onTap: () {},
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.tertiaryContainer.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppColors.tertiary, size: 24),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.onSurface),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceChart() {
    final heights = [0.40, 0.65, 0.85, 0.55, 0.95, 0.30, 0.20];
    final days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    return GlassCard(
      padding: const EdgeInsets.all(20),
      borderRadius: BorderRadius.circular(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Weekly Performance',
                    style: TextStyle(fontFamily: 'Inter', fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.onSurface),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Resolution rate +12% vs last week',
                    style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: AppColors.onSurfaceVariant),
                  ),
                ],
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.tertiaryContainer,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Top Performer',
                  style: TextStyle(fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.tertiary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 120,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(7, (i) {
                final isTallest = heights[i] == heights.reduce((a, b) => a > b ? a : b);
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text(
                                days[i],
                                style: TextStyle(
                                  fontFamily: 'Inter', fontSize: 10,
                                  color: AppColors.onSurfaceVariant.withOpacity(0.6),
                                ),
                              ),
                              const SizedBox(height: 4),
                              AnimatedContainer(
                                duration: Duration(milliseconds: 300 + i * 50),
                                height: 80 * heights[i],
                                decoration: BoxDecoration(
                                  color: isTallest ? AppColors.tertiary : AppColors.tertiary.withOpacity(0.5),
                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                                  boxShadow: isTallest
                                      ? [BoxShadow(color: AppColors.tertiary.withOpacity(0.4), blurRadius: 8)]
                                      : null,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: AppColors.tertiary,
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: AppColors.tertiary.withOpacity(0.5), blurRadius: 6)],
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'SYSTEM SYNC: 100%',
                style: TextStyle(
                  fontFamily: 'Inter', fontSize: 9, fontWeight: FontWeight.w600,
                  color: AppColors.onSurfaceVariant.withOpacity(0.6), letterSpacing: 0.8,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MapGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.onSurface.withOpacity(0.04)
      ..strokeWidth = 1;

    // Horizontal lines
    for (double y = 0; y < size.height; y += 20) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
    // Vertical lines
    for (double x = 0; x < size.width; x += 20) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    // Diagonal "road" lines
    final roadPaint = Paint()
      ..color = AppColors.onSurface.withOpacity(0.08)
      ..strokeWidth = 1.5;

    for (double i = -size.height; i < size.width + size.height; i += 60) {
      canvas.drawLine(Offset(i, 0), Offset(i + size.height, size.height), roadPaint);
    }
  }

  @override
  bool shouldRepaint(_) => false;
}

