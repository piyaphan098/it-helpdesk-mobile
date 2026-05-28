import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../repositories/review_repository.dart';
import '../../../features/auth/presentation/providers/auth_provider.dart';

/// เปิด dialog ให้ user รีวิว — คืน true ถ้า submit สำเร็จ
Future<bool> showReviewDialog({
  required BuildContext context,
  required WidgetRef ref,
  required String ticketId,
  required String technicianId,
}) async {
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _ReviewDialog(
      ticketId: ticketId,
      technicianId: technicianId,
    ),
  );
  return result ?? false;
}

class _ReviewDialog extends ConsumerStatefulWidget {
  const _ReviewDialog({
    required this.ticketId,
    required this.technicianId,
  });
  final String ticketId;
  final String technicianId;

  @override
  ConsumerState<_ReviewDialog> createState() => _ReviewDialogState();
}

class _ReviewDialogState extends ConsumerState<_ReviewDialog> {
  int _rating = 0;
  final _commentController = TextEditingController();
  bool _isSubmitting = false;

  static const _labels = ['', 'แย่มาก', 'แย่', 'พอใช้', 'ดี', 'ดีมาก'];
  static const _emojis = ['', '😞', '😕', '😐', '😊', '🤩'];

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_rating == 0) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('กรุณาเลือกคะแนนก่อน')));
      return;
    }
    final profile = ref.read(currentProfileProvider).valueOrNull;
    if (profile == null) return;

    setState(() => _isSubmitting = true);
    try {
      await ref.read(reviewRepositoryProvider).submitReview(
            ticketId: widget.ticketId,
            reviewerId: profile.id,
            technicianId: widget.technicianId,
            rating: _rating,
            comment: _commentController.text.trim(),
          );
      ref.invalidate(ticketReviewProvider(widget.ticketId));
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      title: Column(
        children: [
          const Icon(Icons.star_rounded, size: 48, color: Colors.amber),
          const SizedBox(height: 8),
          Text('ให้คะแนนการบริการ',
              style: theme.textTheme.titleLarge,
              textAlign: TextAlign.center),
          const SizedBox(height: 4),
          Text('งานเสร็จแล้ว! ช่วยประเมินการให้บริการด้วยนะครับ',
              style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.outline),
              textAlign: TextAlign.center),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 20),
          // ── ดาว ──
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (i) {
              final star = i + 1;
              return GestureDetector(
                onTap: () => setState(() => _rating = star),
                child: AnimatedScale(
                  scale: _rating >= star ? 1.2 : 1.0,
                  duration: const Duration(milliseconds: 150),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Icon(
                      _rating >= star ? Icons.star_rounded : Icons.star_outline_rounded,
                      color: _rating >= star ? Colors.amber : Colors.grey[400],
                      size: 42,
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 8),
          // Label + emoji
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: _rating > 0
                ? Text(
                    '${_emojis[_rating]}  ${_labels[_rating]}',
                    key: ValueKey(_rating),
                    style: theme.textTheme.titleMedium?.copyWith(
                        color: _ratingColor(_rating)),
                  )
                : Text('แตะดาวเพื่อให้คะแนน',
                    key: const ValueKey(0),
                    style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.outline)),
          ),
          const SizedBox(height: 20),
          // ── ความคิดเห็น ──
          TextField(
            controller: _commentController,
            maxLines: 3,
            maxLength: 200,
            decoration: InputDecoration(
              hintText: 'ความคิดเห็นเพิ่มเติม (ไม่บังคับ)',
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12)),
              contentPadding: const EdgeInsets.all(12),
            ),
          ),
          const SizedBox(height: 4),
        ],
      ),
      actions: [
        TextButton(
          onPressed:
              _isSubmitting ? null : () => Navigator.pop(context, false),
          child: const Text('ข้ามไปก่อน'),
        ),
        FilledButton(
          onPressed: _isSubmitting ? null : _submit,
          child: _isSubmitting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
              : const Text('ส่งรีวิว'),
        ),
      ],
    );
  }

  Color _ratingColor(int r) => switch (r) {
        1 => Colors.red,
        2 => Colors.orange,
        3 => Colors.amber,
        4 => Colors.lightGreen,
        5 => Colors.green,
        _ => Colors.grey,
      };
}

/// Widget แสดง review ที่ให้ไปแล้ว (read-only)
class ReviewSummaryCard extends StatelessWidget {
  const ReviewSummaryCard({super.key, required this.rating, this.comment});
  final int rating;
  final String? comment;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.amber.withValues(alpha: 0.08),
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.star_rounded, color: Colors.amber, size: 20),
                const SizedBox(width: 6),
                Text('คุณได้รีวิวงานนี้แล้ว',
                    style: Theme.of(context)
                        .textTheme
                        .labelLarge
                        ?.copyWith(color: Colors.amber[800])),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: List.generate(
                5,
                (i) => Icon(
                  i < rating ? Icons.star_rounded : Icons.star_outline_rounded,
                  color: Colors.amber,
                  size: 22,
                ),
              ),
            ),
            if (comment != null && comment!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('"$comment"',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontStyle: FontStyle.italic,
                      color:
                          Theme.of(context).colorScheme.onSurface)),
            ],
          ],
        ),
      ),
    );
  }
}


