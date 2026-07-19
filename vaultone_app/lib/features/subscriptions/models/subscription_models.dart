class SubscriptionPlan {
  const SubscriptionPlan({
    required this.id,
    required this.name,
    required this.description,
    required this.storageGb,
    required this.priceInr,
    required this.billingDays,
    required this.features,
    required this.whyPurchase,
    required this.isPremium,
  });

  final int id;
  final int storageGb;
  final int billingDays;
  final String name;
  final String description;
  final double priceInr;
  final List<String> features;
  final List<String> whyPurchase;
  final bool isPremium;

  factory SubscriptionPlan.fromJson(Map<String, dynamic> json) {
    return SubscriptionPlan(
      id: json['id'] as int,
      name: json['name'].toString(),
      description: json['description']?.toString() ?? '',
      storageGb: json['storage_gb'] as int,
      priceInr: (json['price_inr'] as num).toDouble(),
      billingDays: json['billing_days'] as int,
      features: List<String>.from(json['features'] ?? const []),
      whyPurchase: List<String>.from(json['why_purchase'] ?? const []),
      isPremium: json['is_premium'] == true,
    );
  }

  String get periodKey {
    if (billingDays <= 31) return 'monthly';
    if (billingDays <= 100) return 'quarterly';
    return 'yearly';
  }
}

class UpiPaymentRequest {
  const UpiPaymentRequest({
    required this.orderId,
    required this.planId,
    required this.planName,
    required this.amountInr,
    required this.upiId,
    required this.receiverName,
    required this.upiUri,
    required this.instructions,
    required this.expiresAt,
  });

  final String orderId;
  final int planId;
  final String planName;
  final double amountInr;
  final String upiId;
  final String receiverName;
  final String upiUri;
  final String instructions;
  final DateTime expiresAt;

  factory UpiPaymentRequest.fromJson(Map<String, dynamic> json) {
    return UpiPaymentRequest(
      orderId: json['order_id'].toString(),
      planId: json['plan_id'] as int,
      planName: json['plan_name']?.toString() ?? 'Plan',
      amountInr: (json['amount_inr'] as num).toDouble(),
      upiId: json['upi_id'].toString(),
      receiverName: json['receiver_name'].toString(),
      upiUri: json['upi_uri'].toString(),
      instructions: json['instructions']?.toString() ?? '',
      expiresAt: DateTime.parse(json['expires_at'].toString()),
    );
  }
}

class PaymentRecord {
  const PaymentRecord({
    required this.orderId,
    required this.status,
    required this.amountInr,
    this.utr,
    this.rejectionReason,
  });

  final String orderId;
  final String status;
  final double amountInr;
  final String? utr;
  final String? rejectionReason;

  factory PaymentRecord.fromJson(Map<String, dynamic> json) {
    return PaymentRecord(
      orderId: json['order_id'].toString(),
      status: json['status'].toString(),
      amountInr: (json['amount_inr'] as num).toDouble(),
      utr: json['utr']?.toString(),
      rejectionReason: json['rejection_reason']?.toString(),
    );
  }
}
