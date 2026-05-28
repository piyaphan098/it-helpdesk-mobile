import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../models/user_profile.dart';

// ─── Providers ────────────────────────────────────────────────────────────────

final technicianPublicProfileProvider =
    FutureProvider.family<UserProfile?, String>((ref, techId) async {
  final data = await Supabase.instance.client
      .from('profiles')
      .select()
      .eq('id', techId)
      .maybeSingle();
  if (data == null) return null;
  return UserProfile.fromJson(data);
});

final _techReviewsProvider =
    FutureProvider.family<List<_Review>, String>((ref, techId) async {
  final data = await Supabase.instance.client
      .from('ticket_reviews')
      .select('rating, comment, created_at')
      .eq('technician_id', techId)
      .order('created_at', ascending: false)
      .limit(20);
  return (data as List)
      .map((r) => _Review(
            rating: r['rating'] as int,
            comment: r['comment'] as String?,
            createdAt: DateTime.parse(r['created_at'] as String),
          ))
      .toList();
});

final _techPostsProvider =
    FutureProvider.family<List<_Post>, String>((ref, techId) async {
  final data = await Supabase.instance.client
      .from('technician_posts')
      .select('id, title, description, image_urls, created_at')
      .eq('technician_id', techId)
      .order('created_at', ascending: false)
      .limit(20);
  return (data as List)
      .map((p) => _Post(
            id: p['id'] as String,
            title: p['title'] as String,
            description: p['description'] as String?,
            imageUrls: (p['image_urls'] as List<dynamic>? ?? [])
                .map((e) => e as String)
                .toList(),
            createdAt: DateTime.parse(p['created_at'] as String),
          ))
      .toList();
});

// ─── Screen ───────────────────────────────────────────────────────────────────

class TechnicianPublicProfileScreen extends ConsumerWidget {
  const TechnicianPublicProfileScreen({
    super.key,
    required this.technicianId,
  });

  final String technicianId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(technicianPublicProfileProvider(technicianId));
    final reviewsAsync = ref.watch(_techReviewsProvider(technicianId));
    final postsAsync = ref.watch(_techPostsProvider(technicianId));
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('โปรไฟล์ช่าง')),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (profile) {
          if (profile == null) return const Center(child: Text('ไม่พบข้อมูล'));

          final reviews = reviewsAsync.valueOrNull ?? [];
          final avg = reviews.isEmpty
              ? 0.0
              : reviews.map((r) => r.rating).reduce((a, b) => a + b) /
                  reviews.length;

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(technicianPublicProfileProvider(technicianId));
              ref.invalidate(_techReviewsProvider(technicianId));
              ref.invalidate(_techPostsProvider(technicianId));
            },
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // ── Header Card ──
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundColor:
                              theme.colorScheme.primaryContainer,
                          backgroundImage: profile.avatarUrl != null
                              ? NetworkImage(profile.avatarUrl!)
                              : null,
                          child: profile.avatarUrl == null
                              ? Text(
                                  profile.initials,
                                  style: theme.textTheme.headlineMedium
                                      ?.copyWith(
                                          color: theme.colorScheme.primary),
                                )
                              : null,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                profile.fullName,
                                style: theme.textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold),
                              ),
                              if (profile.department != null)
                                Text(
                                  profile.department!,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                      color: theme.colorScheme.outline),
                                ),
                              const SizedBox(height: 8),
                              // Rating
                              Row(children: [
                                ...List.generate(5, (i) => Icon(
                                  i < avg.round()
                                      ? Icons.star_rounded
                                      : Icons.star_outline_rounded,
                                  color: Colors.amber, size: 18,
                                )),
                                const SizedBox(width: 6),
                                Text(
                                  avg > 0
                                      ? '${avg.toStringAsFixed(1)} (${reviews.length} รีวิว)'
                                      : 'ยังไม่มีรีวิว',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: avg > 0
                                        ? Colors.amber[800]
                                        : theme.colorScheme.outline,
                                  ),
                                ),
                              ]),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // ── Stats ──
                reviewsAsync.maybeWhen(
                  data: (reviews) {
                    if (reviews.isEmpty) return const SizedBox.shrink();
                    final avg = reviews.map((r) => r.rating)
                            .reduce((a, b) => a + b) /
                        reviews.length;
                    final stars = [5, 4, 3, 2, 1].map((s) =>
                        reviews.where((r) => r.rating == s).length).toList();
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('สรุปคะแนน',
                                style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold)),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Column(children: [
                                  Text(
                                    avg.toStringAsFixed(1),
                                    style: theme.textTheme.displaySmall
                                        ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.amber[700]),
                                  ),
                                  Row(children: List.generate(5, (i) => Icon(
                                    i < avg.round()
                                        ? Icons.star_rounded
                                        : Icons.star_outline_rounded,
                                    color: Colors.amber, size: 14,
                                  ))),
                                  Text('${reviews.length} รีวิว',
                                      style: theme.textTheme.labelSmall
                                          ?.copyWith(
                                              color:
                                                  theme.colorScheme.outline)),
                                ]),
                                const SizedBox(width: 20),
                                Expanded(
                                  child: Column(
                                    children: List.generate(5, (i) {
                                      final star = 5 - i;
                                      final count = stars[i];
                                      final pct = reviews.isEmpty
                                          ? 0.0
                                          : count / reviews.length;
                                      return Padding(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 2),
                                        child: Row(children: [
                                          Text('$star',
                                              style: theme.textTheme.labelSmall),
                                          const SizedBox(width: 4),
                                          Icon(Icons.star_rounded,
                                              color: Colors.amber, size: 12),
                                          const SizedBox(width: 6),
                                          Expanded(
                                            child: ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                              child: LinearProgressIndicator(
                                                value: pct,
                                                minHeight: 6,
                                                backgroundColor: theme
                                                    .colorScheme
                                                    .surfaceContainerHighest,
                                                valueColor:
                                                    AlwaysStoppedAnimation(
                                                        Colors.amber),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Text('$count',
                                              style: theme.textTheme.labelSmall
                                                  ?.copyWith(
                                                      color: theme.colorScheme
                                                          .outline)),
                                        ]),
                                      );
                                    }),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  orElse: () => const SizedBox.shrink(),
                ),
                const SizedBox(height: 16),

                // ── Portfolio Posts ──
                postsAsync.when(
                  loading: () => const Center(
                      child: CircularProgressIndicator()),
                  error: (_, __) => const SizedBox.shrink(),
                  data: (posts) {
                    if (posts.isEmpty) return const SizedBox.shrink();
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('ผลงาน (${posts.length})',
                            style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        ...posts.map((p) => _PostCard(post: p)),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 16),

                // ── Reviews ──
                reviewsAsync.when(
                  loading: () => const Center(
                      child: CircularProgressIndicator()),
                  error: (_, __) => const SizedBox.shrink(),
                  data: (reviews) {
                    if (reviews.isEmpty) return const SizedBox.shrink();
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('รีวิวล่าสุด',
                            style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        ...reviews.map((r) => _ReviewCard(review: r)),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ─── Post Card ────────────────────────────────────────────────────────────────
class _PostCard extends StatelessWidget {
  const _PostCard({required this.post});
  final _Post post;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      clipBehavior: Clip.hardEdge,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (post.imageUrls.isNotEmpty)
            SizedBox(
              height: 180,
              child: PageView.builder(
                itemCount: post.imageUrls.length,
                itemBuilder: (_, i) => Image.network(
                  post.imageUrls[i],
                  fit: BoxFit.cover,
                  width: double.infinity,
                  errorBuilder: (_, __, ___) => Container(
                    color: theme.colorScheme.surfaceContainerHighest,
                    child: const Icon(Icons.broken_image_outlined,
                        size: 40, color: Colors.white38),
                  ),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(post.title,
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.bold)),
                if (post.description != null &&
                    post.description!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    post.description!,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: theme.colorScheme.outline),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 6),
                Text(
                  '${post.createdAt.day}/${post.createdAt.month}/${post.createdAt.year}',
                  style: theme.textTheme.labelSmall
                      ?.copyWith(color: theme.colorScheme.outline),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Review Card ──────────────────────────────────────────────────────────────
class _ReviewCard extends StatelessWidget {
  const _ReviewCard({required this.review});
  final _Review review;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Row(
                children: List.generate(5, (i) => Icon(
                  i < review.rating
                      ? Icons.star_rounded
                      : Icons.star_outline_rounded,
                  color: Colors.amber, size: 16,
                )),
              ),
              const SizedBox(width: 8),
              Text(
                '${review.createdAt.day}/${review.createdAt.month}/${review.createdAt.year}',
                style: theme.textTheme.labelSmall
                    ?.copyWith(color: theme.colorScheme.outline),
              ),
            ]),
            if (review.comment != null && review.comment!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(review.comment!, style: theme.textTheme.bodySmall),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Data classes ─────────────────────────────────────────────────────────────
class _Review {
  const _Review({
    required this.rating,
    required this.createdAt,
    this.comment,
  });
  final int rating;
  final String? comment;
  final DateTime createdAt;
}

class _Post {
  const _Post({
    required this.id,
    required this.title,
    required this.createdAt,
    this.description,
    this.imageUrls = const [],
  });
  final String id;
  final String title;
  final String? description;
  final List<String> imageUrls;
  final DateTime createdAt;
}


