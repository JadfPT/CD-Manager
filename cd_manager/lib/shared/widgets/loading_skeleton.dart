import 'package:flutter/material.dart';

class LoadingSkeleton extends StatefulWidget {
  const LoadingSkeleton({
    required this.child,
    super.key,
  });

  final Widget child;

  @override
  State<LoadingSkeleton> createState() => _LoadingSkeletonState();
}

class _LoadingSkeletonState extends State<LoadingSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = _controller.value;
        final base = Color.lerp(
          colors.surfaceContainerHighest.withValues(alpha: 0.42),
          colors.surfaceContainerHighest.withValues(alpha: 0.82),
          t,
        );

        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: colors.copyWith(surfaceContainerHighest: base),
          ),
          child: child!,
        );
      },
      child: widget.child,
    );
  }
}

class SkeletonBox extends StatelessWidget {
  const SkeletonBox({
    this.width,
    this.height = 14,
    this.radius = 8,
    super.key,
  });

  final double? width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .surfaceContainerHighest
            .withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

class AlbumTileSkeleton extends StatelessWidget {
  const AlbumTileSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            SkeletonBox(width: 74, height: 74, radius: 14),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonBox(width: 160, height: 16),
                  SizedBox(height: 8),
                  SkeletonBox(width: 120, height: 12),
                  SizedBox(height: 14),
                  Row(
                    children: [
                      SkeletonBox(width: 56, height: 22, radius: 999),
                      SizedBox(width: 8),
                      SkeletonBox(width: 96, height: 22, radius: 999),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
