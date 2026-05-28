import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

// ─── Models ───────────────────────────────────────────────────────────────────
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

// ─── Provider ─────────────────────────────────────────────────────────────────
final myPostsProvider =
    FutureProvider.family<List<_Post>, String>((ref, techId) async {
  final data = await Supabase.instance.client
      .from('technician_posts')
      .select()
      .eq('technician_id', techId)
      .order('created_at', ascending: false);
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
class ManagePostsScreen extends ConsumerStatefulWidget {
  const ManagePostsScreen({super.key, required this.technicianId});
  final String technicianId;

  @override
  ConsumerState<ManagePostsScreen> createState() => _ManagePostsScreenState();
}

class _ManagePostsScreenState extends ConsumerState<ManagePostsScreen> {
  bool _isDeleting = false;

  Future<void> _deletePost(String postId) async {
    setState(() => _isDeleting = true);
    try {
      await Supabase.instance.client
          .from('technician_posts')
          .delete()
          .eq('id', postId);
      ref.invalidate(myPostsProvider(widget.technicianId));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ลบโพสต์เรียบร้อย')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _isDeleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final postsAsync = ref.watch(myPostsProvider(widget.technicianId));
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('จัดการผลงาน')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AddPostScreen(technicianId: widget.technicianId),
            ),
          );
          ref.invalidate(myPostsProvider(widget.technicianId));
        },
        icon: const Icon(Icons.add_photo_alternate_rounded),
        label: const Text('เพิ่มผลงาน'),
      ),
      body: postsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (posts) {
          if (posts.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.photo_library_outlined,
                      size: 64,
                      color: theme.colorScheme.outline.withValues(alpha: 0.4)),
                  const SizedBox(height: 16),
                  Text('ยังไม่มีผลงาน',
                      style: theme.textTheme.titleMedium
                          ?.copyWith(color: theme.colorScheme.outline)),
                  const SizedBox(height: 8),
                  Text('เพิ่มรูปผลงานเพื่อสร้างความน่าเชื่อถือ',
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: theme.colorScheme.outline)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            itemCount: posts.length,
            itemBuilder: (context, i) {
              final post = posts[i];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                clipBehavior: Clip.hardEdge,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (post.imageUrls.isNotEmpty)
                      SizedBox(
                        height: 160,
                        child: Image.network(
                          post.imageUrls.first,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: theme.colorScheme.surfaceContainerHighest,
                            child: const Icon(Icons.broken_image_outlined,
                                size: 40),
                          ),
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(post.title,
                                    style: theme.textTheme.titleSmall?.copyWith(
                                        fontWeight: FontWeight.bold)),
                                if (post.description != null &&
                                    post.description!.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(post.description!,
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                              color: theme.colorScheme.outline),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis),
                                ],
                                const SizedBox(height: 4),
                                if (post.imageUrls.length > 1)
                                  Text(
                                    '${post.imageUrls.length} รูป',
                                    style: theme.textTheme.labelSmall?.copyWith(
                                        color: theme.colorScheme.primary),
                                  ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: _isDeleting
                                ? null
                                : () async {
                                    final ok = await showDialog<bool>(
                                      context: context,
                                      builder: (_) => AlertDialog(
                                        title: const Text('ลบผลงาน'),
                                        content: const Text(
                                            'ต้องการลบโพสต์นี้ใช่ไหม?'),
                                        actions: [
                                          TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(context, false),
                                              child: const Text('ยกเลิก')),
                                          FilledButton(
                                            style: FilledButton.styleFrom(
                                                backgroundColor: Colors.red),
                                            onPressed: () =>
                                                Navigator.pop(context, true),
                                            child: const Text('ลบ'),
                                          ),
                                        ],
                                      ),
                                    );
                                    if (ok == true) _deletePost(post.id);
                                  },
                            icon: const Icon(Icons.delete_outline,
                                color: Colors.red),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// ─── Add Post Screen ──────────────────────────────────────────────────────────
class AddPostScreen extends ConsumerStatefulWidget {
  const AddPostScreen({super.key, required this.technicianId});
  final String technicianId;

  @override
  ConsumerState<AddPostScreen> createState() => _AddPostScreenState();
}

class _AddPostScreenState extends ConsumerState<AddPostScreen> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final List<XFile> _images = [];
  final List<Uint8List> _imageBytes = [];
  bool _isSaving = false;

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final picked = await picker.pickMultiImage(imageQuality: 80);
    if (picked.isNotEmpty) {
      final bytes = await Future.wait(picked.map((f) => f.readAsBytes()));
      setState(() {
        _images.addAll(picked);
        _imageBytes.addAll(bytes);
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final client = Supabase.instance.client;
      final urls = <String>[];

      for (final img in _images) {
        final bytes = await img.readAsBytes();
        final ext = img.name.split('.').last.toLowerCase();
        final fileName = '${widget.technicianId}/${const Uuid().v4()}.$ext';
        await client.storage.from('technician-posts').uploadBinary(
              fileName,
              bytes,
              fileOptions: FileOptions(
                  contentType: ext == 'png' ? 'image/png' : 'image/jpeg'),
            );
        urls.add(
            client.storage.from('technician-posts').getPublicUrl(fileName));
      }

      await client.from('technician_posts').insert({
        'technician_id': widget.technicianId,
        'title': _titleCtrl.text.trim(),
        'description':
            _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
        'image_urls': urls,
      });

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('เพิ่มผลงาน'),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _save,
            child: _isSaving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('บันทึก'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Image picker
            GestureDetector(
              onTap: _pickImages,
              child: Container(
                height: 160,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: theme.colorScheme.outline.withValues(alpha: 0.3),
                      style: BorderStyle.solid),
                ),
                child: _images.isEmpty
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_photo_alternate_outlined,
                              size: 48,
                              color: theme.colorScheme.outline
                                  .withValues(alpha: 0.6)),
                          const SizedBox(height: 8),
                          Text('แตะเพื่อเพิ่มรูปภาพ',
                              style: theme.textTheme.bodyMedium
                                  ?.copyWith(color: theme.colorScheme.outline)),
                        ],
                      )
                    : ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.all(12),
                        itemCount: _images.length + 1,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (context, i) {
                          if (i == _images.length) {
                            return GestureDetector(
                              onTap: _pickImages,
                              child: Container(
                                width: 120,
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.surface,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                      color: theme.colorScheme.outline
                                          .withValues(alpha: 0.3)),
                                ),
                                child: Icon(Icons.add_rounded,
                                    color: theme.colorScheme.outline),
                              ),
                            );
                          }
                          return Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.memory(
                                  _imageBytes[i],
                                  width: 120,
                                  height: double.infinity,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              Positioned(
                                top: 4,
                                right: 4,
                                child: GestureDetector(
                                  onTap: () => setState(() {
                                    _images.removeAt(i);
                                    _imageBytes.removeAt(i);
                                  }),
                                  child: Container(
                                    decoration: const BoxDecoration(
                                      color: Colors.black54,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.close,
                                        color: Colors.white, size: 18),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
              ),
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _titleCtrl,
              decoration: const InputDecoration(
                labelText: 'ชื่อผลงาน *',
                border: OutlineInputBorder(),
                hintText: 'เช่น ซ่อมคอมพิวเตอร์ชั้น 3',
              ),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'กรุณาระบุชื่อ' : null,
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: _descCtrl,
              decoration: const InputDecoration(
                labelText: 'รายละเอียด (ไม่บังคับ)',
                border: OutlineInputBorder(),
                hintText: 'อธิบายงานที่ทำ...',
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}


