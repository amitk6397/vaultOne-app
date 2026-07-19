import 'dart:io';

import 'package:flutter_riverpod/legacy.dart';

import '../../../core/localization/app_language_controller.dart';
import '../models/subscription_models.dart';
import '../repositories/subscription_repository.dart';

class SubscriptionState {
  const SubscriptionState({
    this.plans = const [],
    this.payments = const [],
    this.loading = true,
    this.processing = false,
    this.processingPlanId,
    this.error,
    this.activeSubscription,
    this.storage,
    this.offers = const [],
  });

  final List<SubscriptionPlan> plans;
  final List<PaymentRecord> payments;
  final bool loading;
  final bool processing;
  final int? processingPlanId;
  final String? error;
  final Map<String, dynamic>? activeSubscription;
  final Map<String, dynamic>? storage;
  final List<Map<String, dynamic>> offers;

  bool get shouldShowSubscription =>
      storage?['should_show_subscription'] == true;

  SubscriptionState copyWith({
    List<SubscriptionPlan>? plans,
    List<PaymentRecord>? payments,
    bool? loading,
    bool? processing,
    int? processingPlanId,
    bool clearProcessingPlan = false,
    String? error,
    bool clearError = false,
    Map<String, dynamic>? activeSubscription,
    bool clearActiveSubscription = false,
    Map<String, dynamic>? storage,
    List<Map<String, dynamic>>? offers,
  }) {
    return SubscriptionState(
      plans: plans ?? this.plans,
      payments: payments ?? this.payments,
      loading: loading ?? this.loading,
      processing: processing ?? this.processing,
      processingPlanId: clearProcessingPlan
          ? null
          : processingPlanId ?? this.processingPlanId,
      error: clearError ? null : error ?? this.error,
      activeSubscription: clearActiveSubscription
          ? null
          : activeSubscription ?? this.activeSubscription,
      storage: storage ?? this.storage,
      offers: offers ?? this.offers,
    );
  }
}

final subscriptionProvider =
    StateNotifierProvider<SubscriptionController, SubscriptionState>((ref) {
      final language = ref.watch(appLanguageProvider);
      return SubscriptionController(
        ref.watch(subscriptionRepositoryProvider),
        language.code,
      )..load();
    });

class SubscriptionController extends StateNotifier<SubscriptionState> {
  SubscriptionController(this._repository, this._languageCode)
    : super(const SubscriptionState());

  final SubscriptionRepository _repository;
  final String _languageCode;

  Future<void> load() async {
    state = state.copyWith(loading: true, clearError: true);
    try {
      final plans = await _repository.fetchPlans(_languageCode);
      final status = await _repository.fetchStatus(_languageCode);
      final paymentData = status['payments'] as List<dynamic>? ?? const [];
      final active = status['subscription'];
      final storageData = status['storage'];
      final offerData = status['offers'] as List<dynamic>? ?? const [];

      state = state.copyWith(
        plans: plans,
        payments: paymentData
            .map(
              (item) => PaymentRecord.fromJson(
                Map<String, dynamic>.from(item as Map),
              ),
            )
            .toList(),
        activeSubscription: active is Map
            ? Map<String, dynamic>.from(active)
            : null,
        clearActiveSubscription: active is! Map,
        storage: storageData is Map
            ? Map<String, dynamic>.from(storageData)
            : null,
        offers: offerData
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList(),
        loading: false,
      );
    } catch (error) {
      state = state.copyWith(loading: false, error: error.toString());
    }
  }

  Future<UpiPaymentRequest?> createPayment(int planId) async {
    if (state.processingPlanId != null) return null;
    state = state.copyWith(
      processing: true,
      processingPlanId: planId,
      clearError: true,
    );
    try {
      return await _repository.createPayment(planId);
    } catch (error) {
      state = state.copyWith(error: error.toString());
      return null;
    } finally {
      state = state.copyWith(processing: false, clearProcessingPlan: true);
    }
  }

  Future<bool> submit({
    required UpiPaymentRequest payment,
    required String utr,
    required double amount,
    required File screenshot,
  }) async {
    state = state.copyWith(processing: true, clearError: true);
    try {
      await _repository.submitPayment(
        payment: payment,
        utr: utr,
        paidAmount: amount,
        screenshot: screenshot,
      );
      await load();
      return true;
    } catch (error) {
      state = state.copyWith(error: error.toString());
      return false;
    } finally {
      state = state.copyWith(processing: false);
    }
  }
}
