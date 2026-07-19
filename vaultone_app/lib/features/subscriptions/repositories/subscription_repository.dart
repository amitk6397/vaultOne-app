import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../constants/app_url.dart';
import '../../../data/base_api_service.dart';
import '../../../data/network_api_service.dart';
import '../models/subscription_models.dart';

final subscriptionRepositoryProvider = Provider<SubscriptionRepository>((ref) {
  return SubscriptionRepository(ref.watch(apiServiceProvider));
});

class SubscriptionRepository {
  const SubscriptionRepository(this._api);

  final BaseApiService _api;

  Future<List<SubscriptionPlan>> fetchPlans(String languageCode) async {
    final response = await _api.get(
      AppUrl.subscriptionPlans,
      queryParameters: {'lang': languageCode},
    );
    final data = response['data'] as List<dynamic>;
    return data
        .map(
          (item) =>
              SubscriptionPlan.fromJson(Map<String, dynamic>.from(item as Map)),
        )
        .toList();
  }

  Future<UpiPaymentRequest> createPayment(int planId) async {
    final response = await _api.post(
      AppUrl.createSubscriptionPayment,
      data: {'plan_id': planId},
    );
    return UpiPaymentRequest.fromJson(
      Map<String, dynamic>.from(response['data'] as Map),
    );
  }

  Future<String> submitPayment({
    required UpiPaymentRequest payment,
    required String utr,
    required double paidAmount,
    required File screenshot,
  }) async {
    final formData = FormData.fromMap({
      'order_id': payment.orderId,
      'utr': utr.trim(),
      'paid_amount_paise': (paidAmount * 100).round(),
      'screenshot': await MultipartFile.fromFile(
        screenshot.path,
        filename: screenshot.uri.pathSegments.last,
      ),
    });
    final response = await _api.post(
      AppUrl.submitSubscriptionPayment,
      data: formData,
    );
    return response['message']?.toString() ?? 'Submitted for verification';
  }

  Future<Map<String, dynamic>> fetchStatus(String languageCode) async {
    final response = await _api.get(
      AppUrl.subscriptionStatus,
      queryParameters: {'lang': languageCode},
    );
    return Map<String, dynamic>.from(response['data'] as Map);
  }
}
