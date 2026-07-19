import 'dart:async';

import 'package:flutter_riverpod/legacy.dart';

import '../../../core/notifications/notification_service.dart';
import '../models/app_notification.dart';
import '../repositories/notification_repository.dart';

class NotificationState {
  const NotificationState({
    this.items = const [],
    this.unreadCount = 0,
    this.loading = false,
    this.processing = false,
    this.error,
  });

  final List<AppNotification> items;
  final int unreadCount;
  final bool loading;
  final bool processing;
  final String? error;

  NotificationState copyWith({
    List<AppNotification>? items,
    int? unreadCount,
    bool? loading,
    bool? processing,
    String? error,
    bool clearError = false,
  }) {
    return NotificationState(
      items: items ?? this.items,
      unreadCount: unreadCount ?? this.unreadCount,
      loading: loading ?? this.loading,
      processing: processing ?? this.processing,
      error: clearError ? null : error ?? this.error,
    );
  }
}

final notificationProvider =
    StateNotifierProvider<NotificationController, NotificationState>((ref) {
      return NotificationController(ref.watch(notificationRepositoryProvider))
        ..load();
    });

class NotificationController extends StateNotifier<NotificationState> {
  NotificationController(this._repository) : super(const NotificationState()) {
    _eventSubscription = NotificationService.instance.notificationEvents.listen(
      (_) => load(),
    );
  }

  final NotificationRepository _repository;
  late final StreamSubscription<void> _eventSubscription;

  @override
  void dispose() {
    _eventSubscription.cancel();
    super.dispose();
  }

  Future<void> load() async {
    state = state.copyWith(loading: true, clearError: true);
    try {
      final results = await Future.wait([
        _repository.fetchNotifications(),
        _repository.fetchUnreadCount(),
      ]);
      state = state.copyWith(
        items: results[0] as List<AppNotification>,
        unreadCount: results[1] as int,
        loading: false,
      );
    } catch (error) {
      state = state.copyWith(loading: false, error: error.toString());
    }
  }

  Future<void> markAsRead(int id) async {
    final index = state.items.indexWhere((item) => item.id == id);
    if (index < 0 || state.items[index].isRead) return;
    try {
      await _repository.markAsRead(id);
      final items = [...state.items];
      items[index] = items[index].copyWith(
        isRead: true,
        readAt: DateTime.now(),
      );
      state = state.copyWith(
        items: items,
        unreadCount: state.unreadCount > 0 ? state.unreadCount - 1 : 0,
      );
    } catch (error) {
      state = state.copyWith(error: error.toString());
    }
  }

  Future<void> markAllAsRead() async {
    state = state.copyWith(processing: true, clearError: true);
    try {
      await _repository.markAllAsRead();
      final now = DateTime.now();
      state = state.copyWith(
        items: state.items
            .map((item) => item.copyWith(isRead: true, readAt: now))
            .toList(),
        unreadCount: 0,
      );
    } catch (error) {
      state = state.copyWith(error: error.toString());
    } finally {
      state = state.copyWith(processing: false);
    }
  }

  Future<bool> delete(int id) async {
    try {
      await _repository.deleteNotification(id);
      final matches = state.items.where((item) => item.id == id);
      final removed = matches.isEmpty ? null : matches.first;
      state = state.copyWith(
        items: state.items.where((item) => item.id != id).toList(),
        unreadCount: removed != null && !removed.isRead
            ? (state.unreadCount > 0 ? state.unreadCount - 1 : 0)
            : state.unreadCount,
      );
      return true;
    } catch (error) {
      state = state.copyWith(error: error.toString());
      return false;
    }
  }

  Future<void> deleteAll() async {
    state = state.copyWith(processing: true, clearError: true);
    try {
      await _repository.deleteAllNotifications();
      state = state.copyWith(items: const [], unreadCount: 0);
    } catch (error) {
      state = state.copyWith(error: error.toString());
    } finally {
      state = state.copyWith(processing: false);
    }
  }
}
