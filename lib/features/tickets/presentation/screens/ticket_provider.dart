import 'package:image_picker/image_picker.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../models/ticket.dart';
import '../../../../repositories/ticket_repository.dart';

/// ดึง tickets ทั้งหมดของ user
final ticketsProvider = FutureProvider<List<Ticket>>((ref) async {
  final repository = ref.watch(ticketRepositoryProvider);
  return repository.getTickets();
});

/// ดึง ticket เดียวตาม id
final ticketDetailProvider =
    FutureProvider.family<Ticket, String>((ref, id) async {
  final repository = ref.watch(ticketRepositoryProvider);
  return repository.getTicket(id);
});

/// Controller สำหรับ create/update ticket
class TicketController extends StateNotifier<AsyncValue<void>> {
  TicketController(this._repository) : super(const AsyncValue.data(null));
  final TicketRepository _repository;

  Future<Ticket?> createTicket({
    required String title,
    required String description,
    required TicketPriority priority,
    required String createdBy,
    String? category,
    List<XFile> images = const [],
    double? latitude,
    double? longitude,
    String? location,
  }) async {
    state = const AsyncValue.loading();
    try {
      final ticket = await _repository.createTicket(
        title: title,
        description: description,
        priority: priority,
        createdBy: createdBy,
        category: category,
        images: images,
        latitude: latitude,
        longitude: longitude,
        location: location,
      );
      state = const AsyncValue.data(null);
      return ticket;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  /// ช่างรับงาน: set assigned_to + เปลี่ยน status เป็น inProgress
  Future<void> acceptTicket(String ticketId, String technicianId) async {
    state = const AsyncValue.loading();
    try {
      await _repository.acceptTicket(ticketId, technicianId);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> updateStatus(String id, TicketStatus status) async {
    state = const AsyncValue.loading();
    try {
      await _repository.updateTicketStatus(id, status);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> cancelTicket(String id, {required String reason}) async {
    state = const AsyncValue.loading();
    try {
      await _repository.cancelTicket(id, reason: reason);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}

final ticketControllerProvider =
    StateNotifierProvider<TicketController, AsyncValue<void>>((ref) {
  final repository = ref.watch(ticketRepositoryProvider);
  return TicketController(repository);
});


