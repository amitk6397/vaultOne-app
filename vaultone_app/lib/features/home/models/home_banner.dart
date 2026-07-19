import '../../../constants/app_url.dart';

class HomeBanner {
  const HomeBanner({
    required this.id,
    required this.image,
    required this.title,
    required this.subtitle,
    required this.ctaLabel,
    this.routeName,
  });

  final int id;
  final String image;
  final String title;
  final String subtitle;
  final String ctaLabel;
  final String? routeName;

  factory HomeBanner.fromJson(Map<String, dynamic> json) {
    return HomeBanner(
      id: json['id'] as int? ?? 0,
      image: AppUrl.resolveResourceUrl(json['image']?.toString()),
      title: json['title'] as String? ?? '',
      subtitle: json['subtitle'] as String? ?? '',
      ctaLabel: json['cta_label'] as String? ?? '',
      routeName: json['route_name'] as String?,
    );
  }
}
