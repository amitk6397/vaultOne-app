import '../../../constants/app_url.dart';

class OnboardingSlide {
  const OnboardingSlide({
    required this.id,
    required this.image,
    required this.title,
    required this.subtitle,
  });

  final int id;
  final String image;
  final String title;
  final String subtitle;

  factory OnboardingSlide.fromJson(Map<String, dynamic> json) {
    return OnboardingSlide(
      id: json['id'] as int,
      image: AppUrl.resolveResourceUrl(json['image']?.toString()),
      title: json['title'] as String? ?? '',
      subtitle: json['subtitle'] as String? ?? '',
    );
  }
}
