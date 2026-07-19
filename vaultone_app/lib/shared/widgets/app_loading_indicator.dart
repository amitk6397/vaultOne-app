import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

class AppLoadingIndicator extends StatelessWidget {
  const AppLoadingIndicator({super.key, this.color, this.size = 36});

  final Color? color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Loading',
      child: LoadingAnimationWidget.staggeredDotsWave(
        color: color ?? Theme.of(context).colorScheme.primary,
        size: size,
      ),
    );
  }
}

class AppLoadingView extends StatelessWidget {
  const AppLoadingView({super.key, this.color, this.size = 44});

  final Color? color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AppLoadingIndicator(color: color, size: size),
    );
  }
}
