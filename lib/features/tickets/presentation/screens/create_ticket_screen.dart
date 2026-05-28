import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';

import '../../../../models/ticket.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/ticket_provider.dart';

class CreateTicketScreen extends ConsumerStatefulWidget {
  const CreateTicketScreen({super.key});

  @override
  ConsumerState<CreateTicketScreen> createState() => _CreateTicketScreenState();
}

class _CreateTicketScreenState extends ConsumerState<CreateTicketScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();

  TicketPriority _priority = TicketPriority.medium;
  String? _category;
  bool _isLoading = false;

  // รูปภาพ
  final List<XFile> _selectedImages = [];
  final _picker = ImagePicker();

  // ตำแหน่ง
  LatLng? _selectedLocation;
  bool _isGettingLocation = false;
  final _mapController = MapController();

  final _categories = ['Hardware', 'Software', 'Network', 'Account', 'Other'];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  // ─── รูปภาพ ───────────────────────────────────────────────

  Future<void> _pickImage(ImageSource source) async {
    if (_selectedImages.length >= 5) {
      _showSnack('แนบรูปได้สูงสุด 5 รูป');
      return;
    }

    final XFile? picked = await _picker.pickImage(
      source: source,
      imageQuality: 80,
      maxWidth: 1920,
    );

    if (picked != null) {
      setState(() => _selectedImages.add(picked));
    }
  }

  void _removeImage(int index) {
    setState(() => _selectedImages.removeAt(index));
  }

  void _showImageSourceSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.camera_alt_rounded),
              title: const Text('ถ่ายรูป'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded),
              title: const Text('เลือกจากคลัง'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // ─── ตำแหน่ง ──────────────────────────────────────────────

  Future<void> _getCurrentLocation() async {
    setState(() => _isGettingLocation = true);
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          _showSnack('กรุณาเปิดสิทธิ์ Location ในการตั้งค่าแอป');
        }
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      final latLng = LatLng(pos.latitude, pos.longitude);
      setState(() => _selectedLocation = latLng);
      _mapController.move(latLng, 16);
    } catch (e) {
      if (mounted) _showSnack('ไม่สามารถดึงตำแหน่งได้: $e');
    } finally {
      if (mounted) setState(() => _isGettingLocation = false);
    }
  }

  void _onMapTap(TapPosition tapPosition, LatLng latLng) {
    setState(() => _selectedLocation = latLng);
  }

  // ─── Submit ───────────────────────────────────────────────

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final user = ref.read(authStateProvider).valueOrNull;
    if (user == null) return;

    setState(() => _isLoading = true);
    try {
      await ref.read(ticketControllerProvider.notifier).createTicket(
            title: _titleController.text.trim(),
            description: _descriptionController.text.trim(),
            priority: _priority,
            createdBy: user.id,
            category: _category,
            images: _selectedImages,
            latitude: _selectedLocation?.latitude,
            longitude: _selectedLocation?.longitude,
            location: _locationController.text.trim(),
          );
      ref.invalidate(ticketsProvider);
      if (mounted) {
        _showSnack('สร้าง Ticket สำเร็จ!');
        context.pop();
      }
    } catch (e) {
      if (mounted) _showSnack('เกิดข้อผิดพลาด: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  // ─── Build ────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final defaultCenter = const LatLng(13.7563, 100.5018); // กรุงเทพ default

    return Scaffold(
      appBar: AppBar(title: const Text('แจ้งปัญหา IT')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ── ข้อมูลพื้นฐาน ──
            _SectionHeader(label: 'ข้อมูลปัญหา'),
            const SizedBox(height: 12),
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'หัวข้อปัญหา *',
                hintText: 'เช่น คอมพิวเตอร์เปิดไม่ติด',
                prefixIcon: Icon(Icons.title_rounded),
              ),
              validator: (v) =>
                  v == null || v.isEmpty ? 'กรุณาระบุหัวข้อ' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'รายละเอียด *',
                hintText: 'อธิบายปัญหาให้ละเอียด',
                alignLabelWithHint: true,
                prefixIcon: Icon(Icons.description_rounded),
              ),
              maxLines: 4,
              validator: (v) =>
                  v == null || v.isEmpty ? 'กรุณาระบุรายละเอียด' : null,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _category,
              decoration: const InputDecoration(
                labelText: 'ประเภทปัญหา',
                prefixIcon: Icon(Icons.category_rounded),
              ),
              hint: const Text('เลือกประเภท'),
              items: _categories
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (v) => setState(() => _category = v),
            ),
            const SizedBox(height: 16),
            Text('ระดับความเร่งด่วน', style: theme.textTheme.labelLarge),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: TicketPriority.values.map((p) {
                final selected = _priority == p;
                return ChoiceChip(
                  label: Text(p.label),
                  selected: selected,
                  onSelected: (_) => setState(() => _priority = p),
                );
              }).toList(),
            ),

            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 8),

            // ── รูปภาพ ──
            _SectionHeader(
              label: 'แนบรูปภาพ',
              subtitle: '(ไม่บังคับ, สูงสุด 5 รูป)',
            ),
            const SizedBox(height: 12),
            _ImagePickerSection(
              images: _selectedImages,
              onAdd: _showImageSourceSheet,
              onRemove: _removeImage,
            ),

            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 8),

            // ── ตำแหน่ง ──
            _SectionHeader(
              label: 'ตำแหน่งที่เกิดปัญหา',
              subtitle: '(ไม่บังคับ)',
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _locationController,
              decoration: const InputDecoration(
                labelText: 'ระบุสถานที่ (ชื่อห้อง / อาคาร)',
                hintText: 'เช่น ห้อง IT ชั้น 3',
                prefixIcon: Icon(Icons.room_rounded),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isGettingLocation ? null : _getCurrentLocation,
                    icon: _isGettingLocation
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.my_location_rounded),
                    label: Text(_isGettingLocation
                        ? 'กำลังดึงตำแหน่ง...'
                        : 'ใช้ตำแหน่งปัจจุบัน'),
                  ),
                ),
                if (_selectedLocation != null) ...[
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () => setState(() => _selectedLocation = null),
                    icon: const Icon(Icons.clear_rounded),
                    tooltip: 'ล้างตำแหน่ง',
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
            // แผนที่ — แสดงเสมอให้ user tap เลือกได้
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                height: 220,
                child: Stack(
                  children: [
                    FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        initialCenter: _selectedLocation ?? defaultCenter,
                        initialZoom: _selectedLocation != null ? 16 : 12,
                        onTap: _onMapTap,
                      ),
                      children: [
                        TileLayer(
                          urlTemplate:
                              'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName:
                              'com.example.it_support_helpdesk',
                        ),
                        if (_selectedLocation != null)
                          MarkerLayer(
                            markers: [
                              Marker(
                                point: _selectedLocation!,
                                width: 40,
                                height: 40,
                                child: const Icon(
                                  Icons.location_pin,
                                  color: Colors.red,
                                  size: 40,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                    // hint overlay เมื่อยังไม่ได้เลือก
                    if (_selectedLocation == null)
                      Positioned(
                        top: 8,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              'แตะแผนที่เพื่อปักหมุด',
                              style:
                                  TextStyle(color: Colors.white, fontSize: 12),
                            ),
                          ),
                        ),
                      ),
                    if (_selectedLocation != null)
                      Positioned(
                        bottom: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.green.shade700,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.check_circle,
                                  color: Colors.white, size: 14),
                              const SizedBox(width: 4),
                              Text(
                                '${_selectedLocation!.latitude.toStringAsFixed(5)}, '
                                '${_selectedLocation!.longitude.toStringAsFixed(5)}',
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                      ),
                    // OpenStreetMap attribution
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        color: Colors.white70,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 4, vertical: 2),
                        child: const Text(
                          '© OpenStreetMap contributors',
                          style: TextStyle(fontSize: 9),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: _isLoading ? null : _submit,
              icon: _isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send_rounded),
              label: Text(_isLoading ? 'กำลังส่ง...' : 'ส่งคำขอ'),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

// ─── Widgets ──────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label, this.subtitle});
  final String label;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(label,
            style: Theme.of(context)
                .textTheme
                .titleSmall
                ?.copyWith(fontWeight: FontWeight.bold)),
        if (subtitle != null) ...[
          const SizedBox(width: 6),
          Text(subtitle!,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: Colors.grey)),
        ],
      ],
    );
  }
}

class _ImagePickerSection extends StatelessWidget {
  const _ImagePickerSection({
    required this.images,
    required this.onAdd,
    required this.onRemove,
  });

  final List<XFile> images;
  final VoidCallback onAdd;
  final void Function(int index) onRemove;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 100,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          // ปุ่มเพิ่มรูป
          if (images.length < 5)
            GestureDetector(
              onTap: onAdd,
              child: Container(
                width: 90,
                height: 90,
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Theme.of(context).colorScheme.primary,
                    width: 1.5,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  color: Theme.of(context)
                      .colorScheme
                      .primaryContainer
                      .withValues(alpha: 0.3),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_photo_alternate_rounded,
                        color: Theme.of(context).colorScheme.primary),
                    const SizedBox(height: 4),
                    Text(
                      'เพิ่มรูป\n${images.length}/5',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          // รูปที่เลือกแล้ว
          ...images.asMap().entries.map((entry) {
            final i = entry.key;
            final file = entry.value;
            return Stack(
              children: [
                Container(
                  width: 90,
                  height: 90,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.grey[800],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: _XFileImage(file: file),
                  ),
                ),
                Positioned(
                  top: 2,
                  right: 10,
                  child: GestureDetector(
                    onTap: () => onRemove(i),
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: Colors.black54,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close,
                          color: Colors.white, size: 14),
                    ),
                  ),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }
}

/// Widget แสดงรูปจาก XFile รองรับทั้ง Web และ Mobile
class _XFileImage extends StatefulWidget {
  const _XFileImage({required this.file});
  final XFile file;

  @override
  State<_XFileImage> createState() => _XFileImageState();
}

class _XFileImageState extends State<_XFileImage> {
  late Future<Uint8List> _bytesFuture;

  @override
  void initState() {
    super.initState();
    _bytesFuture = widget.file.readAsBytes();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List>(
      future: _bytesFuture,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return Image.memory(snapshot.data!, fit: BoxFit.cover);
        }
        return const Center(child: CircularProgressIndicator(strokeWidth: 2));
      },
    );
  }
}
