import 'package:flutter/material.dart';
import '../../../../theme/app_theme.dart';
import '../../../../widgets/cyber/glass_card.dart';
import '../../../../widgets/cyber/cyber_widgets.dart';

class TechnicianProfileScreen extends StatefulWidget {
  final ValueChanged<int>? onNavTap;

  const TechnicianProfileScreen({super.key, this.onNavTap});

  @override
  State<TechnicianProfileScreen> createState() => _TechnicianProfileScreenState();
}

class _TechnicianProfileScreenState extends State<TechnicianProfileScreen>
    with SingleTickerProviderStateMixin {
  bool _darkMode = true;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.1).animate(
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
    return Scaffold(
      backgroundColor: AppColors.background,
      extendBody: true,
      body: Stack(
        children: [
          // Subtle background glow
          Positioned(
            top: -100,
            left: MediaQuery.of(context).size.width / 2 - 150,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [AppColors.tertiary.withOpacity(0.07), Colors.transparent],
                ),
              ),
            ),
          ),
          CustomScrollView(
            slivers: [
              SliverAppBar(
                pinned: true,
                backgroundColor: AppColors.surface.withOpacity(0.7),
                toolbarHeight: 64,
                elevation: 0,
                title: Row(
                  children: [
                    const Text(
                      'IT Helpdesk',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.tertiary,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.notifications_outlined, color: AppColors.onSurfaceVariant),
                    onPressed: () {},
                  ),
                ],
                bottom: PreferredSize(
                  preferredSize: Size.zero,
                  child: Container(height: 1, color: Colors.white.withOpacity(0.1)),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 32, 20, 120),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _buildProfileHeader(),
                    const SizedBox(height: 24),
                    _buildStatsRow(),
                    const SizedBox(height: 28),
                    _buildSettingsSection(),
                    const SizedBox(height: 16),
                    _buildDarkModeCard(),
                    const SizedBox(height: 20),
                    _buildLogOutButton(),
                    const SizedBox(height: 24),
                    _buildVersionFooter(),
                  ]),
                ),
              ),
            ],
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 4,
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

  Widget _buildProfileHeader() {
    return Column(
      children: [
        // Avatar with cyan ring
        Stack(
          alignment: Alignment.center,
          children: [
            // Outer glow ring
            Container(
              width: 116,
              height: 116,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.tertiary.withOpacity(0.3),
                    blurRadius: 24,
                    spreadRadius: 4,
                  ),
                ],
              ),
            ),
            // Cyan border ring
            Container(
              width: 108,
              height: 108,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: SweepGradient(
                  colors: [
                    AppColors.tertiary,
                    AppColors.tertiary.withOpacity(0.2),
                    AppColors.tertiary.withOpacity(0.8),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.tertiary.withOpacity(0.4),
                    blurRadius: 12,
                  ),
                ],
              ),
            ),
            // Avatar image
            Container(
              width: 100,
              height: 100,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                image: DecorationImage(
                  image: NetworkImage('https://lh3.googleusercontent.com/aida-public/AB6AXuBTGVfqhqKsOCi9aY6K9KVjmGQPLxEVXH9cVt4Kgd6T3G7WjE_vAKCHmLHkm8JvhevTcwN1gFoW6Mu0FQgfN4wEGJHdHzjV4l30WtMvNlAFQkHSdYWKi0hxaP3pIuY8ZHK8e_YfnEH_RHjVHWyULVEiKMTvhNGWBGkSFm_v0a4K-IcKVA3R9uPf-RhHI7CUAXBjIqU_j-cNgaekT8cCkVEy5NRg9iy16jE_QK8PGa9j5LZJQ2OY0WL2IgL_r4'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            // Online dot
            Positioned(
              bottom: 6,
              right: 6,
              child: AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (_, child) => Transform.scale(
                  scale: _pulseAnimation.value,
                  child: child,
                ),
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: AppColors.tertiary,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.background, width: 2.5),
                    boxShadow: [BoxShadow(color: AppColors.tertiary.withOpacity(0.6), blurRadius: 8)],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const Text(
          'Alex Rivera',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: AppColors.onSurface,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        // Badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.tertiaryContainer,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.tertiary.withOpacity(0.3), width: 1),
          ),
          child: const Text(
            'SENIOR TECHNICIAN',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.tertiary,
              letterSpacing: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsRow() {
    return Column(
      children: [
        // Tickets Resolved - full width
        GlassCard(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tickets Resolved',
                    style: TextStyle(
                      fontFamily: 'Inter', fontSize: 13, color: AppColors.onSurfaceVariant,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '1,284',
                    style: TextStyle(
                      fontFamily: 'Inter', fontSize: 28, fontWeight: FontWeight.bold,
                      color: AppColors.tertiary,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.tertiaryContainer,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.tertiary.withOpacity(0.3), width: 1),
                ),
                child: const Icon(Icons.check_circle_outline, color: AppColors.tertiary, size: 24),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Rating & Years row
        Row(
          children: [
            Expanded(
              child: GlassCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Rating',
                      style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: AppColors.onSurfaceVariant),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Text(
                          '4.9',
                          style: TextStyle(
                            fontFamily: 'Inter', fontSize: 22, fontWeight: FontWeight.bold,
                            color: AppColors.onSurface,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(Icons.star, color: Color(0xFFFFB800), size: 20),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GlassCard(
                padding: const EdgeInsets.all(16),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Years Active',
                      style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: AppColors.onSurfaceVariant),
                    ),
                    SizedBox(height: 6),
                    Text(
                      '4.5 yrs',
                      style: TextStyle(
                        fontFamily: 'Inter', fontSize: 22, fontWeight: FontWeight.bold,
                        color: AppColors.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSettingsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 12),
          child: Text(
            'SETTINGS',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.onSurfaceVariant,
              letterSpacing: 1.5,
            ),
          ),
        ),
        GlassCard(
          borderRadius: BorderRadius.circular(16),
          child: Column(
            children: [
              _buildSettingsItem(Icons.person_outline, 'Account', null, isFirst: true),
              _buildDivider(),
              _buildSettingsItem(Icons.shield_outlined, 'Security', null),
              _buildDivider(),
              _buildSettingsItem(
                Icons.notifications_outlined,
                'Notifications',
                null,
                subtitle: 'Push, Email',
              ),
              _buildDivider(),
              _buildSettingsItem(Icons.settings_outlined, 'App Preferences', null, isLast: true),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsItem(IconData icon, String title, VoidCallback? onTap, {String? subtitle, bool isFirst = false, bool isLast = false}) {
    return GestureDetector(
      onTap: onTap ?? () {},
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: AppColors.onSurface, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontFamily: 'Inter', fontSize: 15, fontWeight: FontWeight.w500, color: AppColors.onSurface),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: AppColors.tertiary),
                    ),
                  ],
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: AppColors.onSurfaceVariant.withOpacity(0.5), size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 1,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      color: Colors.white.withOpacity(0.06),
    );
  }

  Widget _buildDarkModeCard() {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.secondaryContainer.withOpacity(0.3),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.dark_mode_outlined, color: AppColors.tertiary, size: 20),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Text(
              'Dark Mode',
              style: TextStyle(fontFamily: 'Inter', fontSize: 15, fontWeight: FontWeight.w500, color: AppColors.onSurface),
            ),
          ),
          Switch(
            value: _darkMode,
            onChanged: (v) => setState(() => _darkMode = v),
            activeColor: AppColors.tertiary,
            activeTrackColor: AppColors.tertiaryContainer,
            inactiveThumbColor: AppColors.onSurfaceVariant,
            inactiveTrackColor: AppColors.surfaceContainerHigh,
          ),
        ],
      ),
    );
  }

  Widget _buildLogOutButton() {
    return GestureDetector(
      onTap: () {},
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: AppColors.errorContainer.withOpacity(0.3),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.errorContainer.withOpacity(0.5), width: 1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.logout, color: AppColors.error, size: 20),
            const SizedBox(width: 10),
            Text(
              'Log Out',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.error,
                shadows: [Shadow(color: AppColors.error.withOpacity(0.4), blurRadius: 10)],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVersionFooter() {
    return Center(
      child: Text(
        'IT Helpdesk V2.4.8 (ENTERPRISE)',
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: AppColors.onSurfaceVariant.withOpacity(0.4),
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}



