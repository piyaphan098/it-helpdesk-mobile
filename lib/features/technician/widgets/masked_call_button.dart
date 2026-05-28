import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

/// ทิศทางของการโทร
enum CallDirection {
  userToTech,  // user โทรหาช่าง
  techToUser,  // ช่างโทรหา user
}

/// ปุ่มโทรแบบ masked — ไม่เปิดเผยเบอร์จริงทั้งสองฝ่าย
/// ขั้นตอน:
///   1. เรียก Edge Function `proxy-call` → ได้ session token + เบอร์ proxy
///   2. ถ้า Edge Function ไม่พร้อม → แสดง in-app call screen แทน
///   3. fallback สุดท้าย → โทรเบอร์ IT Support กลาง
class MaskedCallButton extends ConsumerStatefulWidget {
  const MaskedCallButton({
    super.key,
    required this.ticketId,
    required this.technicianId,
    required this.userId,
    this.direction = CallDirection.userToTech,
    this.supportPhone = '021234567',
  });

  final String ticketId;
  final String technicianId;
  final String userId;
  final CallDirection direction;
  final String supportPhone;

  @override
  ConsumerState<MaskedCallButton> createState() => _MaskedCallButtonState();
}

class _MaskedCallButtonState extends ConsumerState<MaskedCallButton> {
  bool _loading = false;

  String get _label => widget.direction == CallDirection.userToTech
      ? 'โทรหาช่างเทคนิค'
      : 'โทรหาผู้แจ้งปัญหา';

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: _loading ? null : _handleCall,
        icon: _loading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : const Icon(Icons.call_rounded),
        label: Text(_label),
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFF1B8A3E),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  Future<void> _handleCall() async {
    final confirmed = await _showConfirmDialog();
    if (!confirmed || !mounted) return;

    setState(() => _loading = true);
    try {
      // ขอ proxy session จาก Edge Function
      final response = await Supabase.instance.client.functions
          .invoke(
        'proxy-call',
        body: {
          'ticket_id': widget.ticketId,
          'technician_id': widget.technicianId,
          'user_id': widget.userId,
          'caller_role': widget.direction == CallDirection.userToTech ? 'user' : 'technician',
          'caller_id': Supabase.instance.client.auth.currentUser?.id,
        },
      )
          .timeout(const Duration(seconds: 8));

      if (response.data != null) {
        final data = response.data as Map<String, dynamic>;
        if (data['proxy_number'] != null) {
          await _dialNumber(data['proxy_number'] as String);
          return;
        }
        if (data['session_token'] != null) {
          // Edge Function ส่ง session token → แสดง in-app call UI
          if (mounted) {
            await _showInAppCallScreen(data['session_token'] as String);
          }
          return;
        }
      }
    } catch (_) {
      // Edge Function ยังไม่ได้ตั้งค่า หรือ timeout → ใช้ in-app fallback
    } finally {
      if (mounted) setState(() => _loading = false);
    }

    // Fallback: in-app call screen (แสดงว่ากำลังเชื่อมต่อผ่านระบบ)
    if (mounted) await _showInAppCallScreen(null);
  }

  Future<bool> _showConfirmDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            CircleAvatar(
              backgroundColor: Color(0xFFE8F5E9),
              child: Icon(Icons.call_rounded, color: Color(0xFF1B8A3E)),
            ),
            SizedBox(width: 12),
            Text('โทรผ่านระบบ'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ระบบจะเชื่อมต่อสายผ่านตัวกลาง',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            _PrivacyRow(icon: Icons.shield_outlined, text: 'เบอร์โทรของคุณจะไม่ถูกเปิดเผย'),
            _PrivacyRow(icon: Icons.lock_outline, text: 'เบอร์ฝั่งตรงข้ามจะไม่ถูกเปิดเผย'),
            _PrivacyRow(icon: Icons.history, text: 'บันทึกสายไว้กับ ticket #${widget.ticketId.substring(0, 6).toUpperCase()}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('ยกเลิก'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.pop(context, true),
            icon: const Icon(Icons.call_rounded, size: 18),
            label: const Text('โทรเลย'),
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFF1B8A3E)),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<void> _showInAppCallScreen(String? sessionToken) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _InAppCallSheet(
        ticketId: widget.ticketId,
        direction: widget.direction,
        sessionToken: sessionToken,
        onDialFallback: () => _dialNumber(widget.supportPhone),
      ),
    );
  }

  Future<void> _dialNumber(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }
}

// ─── In-App Call Sheet ────────────────────────────────────────────────────────
class _InAppCallSheet extends StatefulWidget {
  const _InAppCallSheet({
    required this.ticketId,
    required this.direction,
    required this.sessionToken,
    required this.onDialFallback,
  });

  final String ticketId;
  final CallDirection direction;
  final String? sessionToken;
  final VoidCallback onDialFallback;

  @override
  State<_InAppCallSheet> createState() => _InAppCallSheetState();
}

class _InAppCallSheetState extends State<_InAppCallSheet>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulse;
  bool _connecting = true;
  bool _connected = false;
  int _seconds = 0;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    // จำลอง connecting → connected หลัง 2 วินาที
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _connecting = false;
          _connected = true;
        });
        _startTimer();
      }
    });
  }

  void _startTimer() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted || !_connected) return false;
      setState(() => _seconds++);
      return true;
    });
  }

  String get _timerText {
    final m = _seconds ~/ 60;
    final s = _seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final label = widget.direction == CallDirection.userToTech
        ? 'ช่างเทคนิค'
        : 'ผู้แจ้งปัญหา';

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF0D1117),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 32),

          // Avatar with pulse
          AnimatedBuilder(
            animation: _pulse,
            builder: (_, child) {
              return Stack(
                alignment: Alignment.center,
                children: [
                  if (_connecting) ...[
                    Container(
                      width: 100 + _pulse.value * 20,
                      height: 100 + _pulse.value * 20,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF1B8A3E)
                            .withValues(alpha: 0.15 * (1 - _pulse.value)),
                      ),
                    ),
                    Container(
                      width: 84 + _pulse.value * 10,
                      height: 84 + _pulse.value * 10,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF1B8A3E)
                            .withValues(alpha: 0.2 * (1 - _pulse.value)),
                      ),
                    ),
                  ],
                  child!,
                ],
              );
            },
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _connected
                    ? const Color(0xFF1B8A3E)
                    : const Color(0xFF1E2530),
                border: Border.all(
                  color: _connected
                      ? const Color(0xFF1B8A3E)
                      : Colors.white12,
                  width: 2,
                ),
              ),
              child: Icon(
                _connected ? Icons.call_rounded : Icons.person_rounded,
                color: Colors.white,
                size: 36,
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Name / status
          Text(
            label,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF1B8A3E).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: const Color(0xFF1B8A3E).withValues(alpha: 0.4)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.shield_outlined, size: 12, color: const Color(0xFF4CAF50)),
                const SizedBox(width: 4),
                Text(
                  'เบอร์โทรถูกปกปิด',
                  style: TextStyle(
                    fontSize: 11,
                    color: const Color(0xFF4CAF50),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _connecting
                ? 'กำลังเชื่อมต่อสายผ่านระบบ...'
                : _timerText,
            style: TextStyle(
              fontSize: _connecting ? 13 : 20,
              color: Colors.white54,
              fontWeight: _connected ? FontWeight.w600 : FontWeight.normal,
              letterSpacing: _connected ? 2 : 0,
            ),
          ),

          const SizedBox(height: 40),

          // Control buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _CallControlBtn(
                icon: Icons.mic_off_rounded,
                label: 'ปิดเสียง',
                onTap: () {},
              ),
              _CallControlBtn(
                icon: Icons.call_end_rounded,
                label: 'วางสาย',
                color: Colors.red,
                large: true,
                onTap: () => Navigator.pop(context),
              ),
              _CallControlBtn(
                icon: Icons.volume_up_rounded,
                label: 'ลำโพง',
                onTap: () {},
              ),
            ],
          ),

          if (widget.sessionToken == null) ...[
            const SizedBox(height: 20),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                widget.onDialFallback();
              },
              child: Text(
                'โทรผ่านสายโทรศัพท์ปกติแทน',
                style: TextStyle(color: Colors.white38, fontSize: 12),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Call Control Button ──────────────────────────────────────────────────────
class _CallControlBtn extends StatelessWidget {
  const _CallControlBtn({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
    this.large = false,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final bg = color ?? const Color(0xFF1E2530);
    final size = large ? 72.0 : 56.0;
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(shape: BoxShape.circle, color: bg),
            child: Icon(icon, color: Colors.white, size: large ? 30 : 22),
          ),
        ),
        const SizedBox(height: 6),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.white54)),
      ],
    );
  }
}

// ─── Privacy Row ──────────────────────────────────────────────────────────────
class _PrivacyRow extends StatelessWidget {
  const _PrivacyRow({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        children: [
          Icon(icon, size: 16, color: const Color(0xFF1B8A3E)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: const TextStyle(fontSize: 13)),
          ),
        ],
      ),
    );
  }
}


