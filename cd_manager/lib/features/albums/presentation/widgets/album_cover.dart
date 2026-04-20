import 'package:flutter/material.dart';

class AlbumCover extends StatelessWidget {
  const AlbumCover({
    required this.coverUrl,
    required this.title,
    this.size = 64,
    super.key,
  });

  final String? coverUrl;
  final String title;
  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    if (coverUrl == null || coverUrl!.trim().isEmpty) {
      return _CoverFrame(
        size: size,
        child: _PlaceholderCover(size: size, title: title),
      );
    }

    return _CoverFrame(
      size: size,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: SizedBox(
          width: size,
          height: size,
          child: Image.network(
            coverUrl!,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return _PlaceholderCover(size: size, title: title);
            },
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Container(
                color: colors.surfaceContainerHighest,
                alignment: Alignment.center,
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: colors.primary,
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _CoverFrame extends StatelessWidget {
  const _CoverFrame({
    required this.size,
    required this.child,
  });

  final double size;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.outlineVariant.withValues(alpha: 0.35)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.20),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }
}

class _PlaceholderCover extends StatelessWidget {
  const _PlaceholderCover({
    required this.size,
    required this.title,
  });

  final double size;
  final String title;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colors.primary.withValues(alpha: 0.22),
            colors.tertiary.withValues(alpha: 0.18),
          ],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.album_outlined,
            color: colors.onSurface,
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Text(
              title,
              style: Theme.of(context).textTheme.labelSmall,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
