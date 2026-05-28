import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/cyber/glass_card.dart';
import '../../../widgets/cyber/cyber_widgets.dart';

class MapTrackingScreen extends StatefulWidget {
  final ValueChanged<int>? onNavTap;

  const MapTrackingScreen({super.key, this.onNavTap});

  @override
  State<MapTrackingScreen> createState() => _MapTrackingScreenState();
}

class _MapTrackingScreenState extends State<MapTrackingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseScaleAnim;
  late Animation<double> _pulseOpacityAnim;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();
    _pulseScaleAnim = Tween<double>(begin: 0.95, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _pulseOpacityAnim = Tween<double>(begin: 1.0, end: 0.3).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: AppColors.background,
      extendBody: true,
      body: Stack(
        children: [
          // Full-screen dark map
          SizedBox(
            width: double.infinity,
            height: double.infinity,
            child: CustomPaint(
              painter: _DarkMapPainter(),
            ),
          ),

          // Top bar
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                children: [
                  // Back button
                  GlassCard(
                    padding: const EdgeInsets.all(10),
                    borderRadius: BorderRadius.circular(12),
                    child: const Icon(Icons.arrow_back, color: AppColors.onSurface, size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'TechPulse',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.tertiary,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const Spacer(),
                  // Avatar
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.tertiary.withOpacity(0.4), width: 2),
                      image: const DecorationImage(
                        image: NetworkImage('https://lh3.googleusercontent.com/aida-public/AB6AXuA0TEUAs_uo1AKYnlx-EGcDCeAST3pH1fLxBpdcfNmjuollipf_WuUOuMzEQ3W5D2EjqCpNP5e_wHb7GKdq_1y9zJwo6o9LfYd723A3_kXNU4cdTlAanakoMUO6vQeezvwSuU6MgWmBq3w3KsrBcIX1v_fRMKElPL3XsaIgDK3F5eS9k0ydHmNhv4ja7-yLzk4qDuEtXJ5Gnh3GQER2JUwY8d6k1mJgxlxSR9WkP4rdGFAIS_iO5Ofguxc2eIYTe64IX2_um-P2aTA'),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Distance widget
          Positioned(
            top: MediaQuery.of(context).padding.top + 72,
            left: 20,
            child: GlassCard(
              padding: const EdgeInsets.all(16),
              borderRadius: BorderRadius.circular(16),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.tertiaryContainer,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.route, color: AppColors.tertiary, size: 22),
                  ),
                  const SizedBox(width: 12),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'DISTANCE',
                        style: TextStyle(
                          fontFamily: 'Inter', fontSize: 10, fontWeight: FontWeight.w600,
                          color: AppColors.onSurfaceVariant, letterSpacing: 1.2,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        '1.4 km',
                        style: TextStyle(
                          fontFamily: 'Inter', fontSize: 20, fontWeight: FontWeight.w700,
                          color: AppColors.onSurface,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // "Your Office" marker
          Positioned(
            top: size.height * 0.28,
            right: size.width * 0.2,
            child: Column(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerHigh,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
                  ),
                  child: const Icon(Icons.person, color: AppColors.onSurface, size: 22),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                  ),
                  child: const Text(
                    'Your Office',
                    style: TextStyle(
                      fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w500,
                      color: AppColors.onSurface,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Technician marker (Alex)
          Positioned(
            bottom: size.height * 0.28,
            left: size.width * 0.35,
            child: Column(
              children: [
                AnimatedBuilder(
                  animation: _pulseController,
                  builder: (_, child) {
                    return Stack(
                      alignment: Alignment.center,
                      children: [
                        Transform.scale(
                          scale: _pulseScaleAnim.value,
                          child: Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.tertiary.withOpacity(_pulseOpacityAnim.value * 0.3),
                            ),
                          ),
                        ),
                        child!,
                      ],
                    );
                  },
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.tertiary,
                      boxShadow: [
                        BoxShadow(color: AppColors.tertiary.withOpacity(0.5), blurRadius: 16),
                      ],
                    ),
                    child: const Icon(Icons.engineering, color: AppColors.onTertiary, size: 24),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
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
                      const Text(
                        'Alex (On Route)',
                        style: TextStyle(
                          fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w500,
                          color: AppColors.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Bottom info card
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Column(
              children: [
                _buildInfoCard(),
                BottomNavigationBar(
                  currentIndex: 3,
                  items: const [
                    BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dashboard'),
                    BottomNavigationBarItem(icon: Icon(Icons.assignment), label: 'Tickets'),
                    BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Map'),
                    BottomNavigationBarItem(icon: Icon(Icons.notifications), label: 'Notifications'),
                    BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
                  ],
                  onTap: widget.onNavTap ?? (_) {},
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return GlassCard(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status row
          Row(
            children: [
              AnimatedBuilder(
                animation: _pulseController,
                builder: (_, __) => Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: AppColors.tertiary,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.tertiary.withOpacity(_pulseOpacityAnim.value),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Technician is en route',
                style: TextStyle(
                  fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w600,
                  color: AppColors.tertiary,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'ETA: 8 mins',
                  style: TextStyle(
                    fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w500,
                    color: AppColors.onSurface,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Technician row
          Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  image: const DecorationImage(
                    image: NetworkImage('https://lh3.googleusercontent.com/aida-public/AB6AXuA0TEUAs_uo1AKYnlx-EGcDCeAST3pH1fLxBpdcfNmjuollipf_WuUOuMzEQ3W5D2EjqCpNP5e_wHb7GKdq_1y9zJwo6o9LfYd723A3_kXNU4cdTlAanakoMUO6vQeezvwSuU6MgWmBq3w3KsrBcIX1v_fRMKElPL3XsaIgDK3F5eS9k0ydHmNhv4ja7-yLzk4qDuEtXJ5Gnh3GQER2JUwY8d6k1mJgxlxSR9WkP4rdGFAIS_iO5Ofguxc2eIYTe64IX2_um-P2aTA'),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Alex Rivera',
                      style: TextStyle(
                        fontFamily: 'Inter', fontSize: 20, fontWeight: FontWeight.bold,
                        color: AppColors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.star, color: Color(0xFFFFB800), size: 14),
                        const SizedBox(width: 4),
                        const Text(
                          '4.9 • Senior Engineer',
                          style: TextStyle(
                            fontFamily: 'Inter', fontSize: 13, color: AppColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Vehicle',
                    style: TextStyle(
                      fontFamily: 'Inter', fontSize: 11, color: AppColors.onSurfaceVariant.withOpacity(0.7),
                    ),
                  ),
                  const Text(
                    'Tech-Van #082',
                    style: TextStyle(
                      fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w600,
                      color: AppColors.onSurface,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Action buttons
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  icon: Icons.chat_bubble_outline,
                  label: 'Message',
                  isPrimary: false,
                  onTap: () {},
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionButton(
                  icon: Icons.phone,
                  label: 'Call Now',
                  isPrimary: true,
                  onTap: () {},
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  Widget _buildActionButton({required IconData icon, required String label, required bool isPrimary, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          gradient: isPrimary
              ? const LinearGradient(colors: [AppColors.secondaryContainer, AppColors.tertiary])
              : null,
          color: isPrimary ? null : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(14),
          border: isPrimary ? null : Border.all(color: Colors.white.withOpacity(0.12), width: 1),
          boxShadow: isPrimary
              ? [BoxShadow(color: AppColors.tertiary.withOpacity(0.3), blurRadius: 12)]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: isPrimary ? AppColors.onPrimary : AppColors.onSurface, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isPrimary ? AppColors.onPrimary : AppColors.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DarkMapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Background
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = const Color(0xFF0a0e12),
    );

    final roadPaint = Paint()
      ..color = const Color(0xFF1a2030).withOpacity(0.8)
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    final roadPaintWide = Paint()
      ..color = const Color(0xFF1e2535)
      ..strokeWidth = 3;

    // Draw grid-like city map
    final gridPaint = Paint()
      ..color = const Color(0xFF131820)
      ..strokeWidth = 0.5;

    for (double y = 0; y < size.height; y += 18) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
    for (double x = 0; x < size.width; x += 18) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }

    // Major roads
    final roads = [
      // Horizontal major
      [0.0, size.height * 0.3, size.width, size.height * 0.3],
      [0.0, size.height * 0.5, size.width, size.height * 0.5],
      [0.0, size.height * 0.7, size.width, size.height * 0.7],
      // Vertical major
      [size.width * 0.25, 0.0, size.width * 0.25, size.height],
      [size.width * 0.5, 0.0, size.width * 0.5, size.height],
      [size.width * 0.75, 0.0, size.width * 0.75, size.height],
    ];

    for (final r in roads) {
      canvas.drawLine(Offset(r[0], r[1]), Offset(r[2], r[3]), roadPaintWide);
    }

    // Minor diagonal roads
    final diagonals = [
      [0.0, size.height * 0.1, size.width * 0.6, size.height * 0.8],
      [size.width * 0.2, 0.0, size.width, size.height * 0.6],
    ];

    for (final d in diagonals) {
      canvas.drawLine(Offset(d[0], d[1]), Offset(d[2], d[3]), roadPaint);
    }

    // Cyan route line (from technician to office)
    final routePaint = Paint()
      ..color = const Color(0xFF2fd9f4).withOpacity(0.6)
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final routePath = Path();
    routePath.moveTo(size.width * 0.42, size.height * 0.72);
    routePath.lineTo(size.width * 0.5, size.height * 0.5);
    routePath.lineTo(size.width * 0.65, size.height * 0.3);
    canvas.drawPath(routePath, routePaint);
  }

  @override
  bool shouldRepaint(_) => false;
}

