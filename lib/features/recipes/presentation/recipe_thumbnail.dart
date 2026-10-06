import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'recipe_providers.dart';

/// Miniatura della ricetta dal percorso relativo [relativePath]; un
/// segnaposto se manca, non si trova o non si legge.
class RecipeThumbnail extends ConsumerWidget {
  const RecipeThumbnail({
    required this.relativePath,
    this.width,
    this.height,
    this.borderRadius = BorderRadius.zero,
    this.placeholderIconSize = 28,
    super.key,
  });

  final String? relativePath;
  final double? width;
  final double? height;
  final BorderRadius borderRadius;
  final double placeholderIconSize;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final path = relativePath;
    final file = path == null
        ? null
        : ref.watch(recipeThumbnailProvider(path)).value;
    final placeholder = _Placeholder(iconSize: placeholderIconSize);
    return ClipRRect(
      borderRadius: borderRadius,
      child: SizedBox(
        width: width,
        height: height,
        child: file == null
            ? placeholder
            : Image.file(
                file,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => placeholder,
              ),
      ),
    );
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder({required this.iconSize});

  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return ColoredBox(
      key: const ValueKey('recipe-thumbnail-placeholder'),
      color: colors.surfaceContainerHighest,
      child: Center(
        child: Icon(
          Icons.restaurant_menu,
          size: iconSize,
          color: colors.onSurfaceVariant,
        ),
      ),
    );
  }
}
