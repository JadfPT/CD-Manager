import 'package:flutter/material.dart';

class WishlistButton extends StatelessWidget {
  const WishlistButton({
    required this.isInWishlist,
    required this.isLoading,
    required this.onPressed,
    super.key,
  });

  final bool isInWishlist;
  final bool isLoading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton.tonalIcon(
      onPressed: isLoading ? null : onPressed,
      icon: isLoading
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(isInWishlist ? Icons.bookmark : Icons.bookmark_outline),
      label: Text(isInWishlist ? 'Na wishlist' : 'Wishlist'),
    );
  }
}