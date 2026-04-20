import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class AppNetworkImage extends StatelessWidget {
  const AppNetworkImage({
    required this.imageUrl,
    required this.width,
    required this.height,
    required this.placeholder,
    this.fit = BoxFit.cover,
    this.borderRadius,
    super.key,
  });

  final String? imageUrl;
  final double width;
  final double height;
  final Widget placeholder;
  final BoxFit fit;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    final normalizedUrl = imageUrl?.trim();
    final hasImage = normalizedUrl != null && normalizedUrl.isNotEmpty;

    final child = hasImage
        ? CachedNetworkImage(
            imageUrl: normalizedUrl,
            width: width,
            height: height,
            fit: fit,
            fadeInDuration: const Duration(milliseconds: 260),
            placeholder: (context, url) => _loadingPlaceholder(context),
            errorWidget: (context, url, error) => placeholder,
          )
        : placeholder;

    if (borderRadius == null) {
      return SizedBox(width: width, height: height, child: child);
    }

    return ClipRRect(
      borderRadius: borderRadius!,
      child: SizedBox(width: width, height: height, child: child),
    );
  }

  Widget _loadingPlaceholder(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      alignment: Alignment.center,
      child: SizedBox(
        width: 18,
        height: 18,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}
