import 'package:flutter/material.dart';

class FavoriteButton extends StatelessWidget {
  const FavoriteButton({
    required this.isFavorite,
    required this.isLoading,
    required this.onPressed,
    super.key,
  });

  final bool isFavorite;
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
          : Icon(isFavorite ? Icons.favorite : Icons.favorite_border),
      label: Text(isFavorite ? 'Nos favoritos' : 'Adicionar favorito'),
    );
  }
}
