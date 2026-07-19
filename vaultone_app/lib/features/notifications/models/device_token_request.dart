class DeviceTokenRequest {
  const DeviceTokenRequest({required this.token, required this.platform});

  final String token;
  final String platform;

  Map<String, dynamic> toJson() => {'token': token, 'platform': platform};
}
