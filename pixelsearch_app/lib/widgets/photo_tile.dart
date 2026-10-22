import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../models/photo.dart';

/// Photographs stay unobscured; their descriptions remain accessible.
class PhotoTile extends StatelessWidget {
  final Photo photo;
  final VoidCallback onTap;
  const PhotoTile({super.key, required this.photo, required this.onTap});
  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: '${photo.displayTitle}, ${Dates.short(photo.date)}',
    child: Material(
      color: Theme.of(context).colorScheme.surfaceContainer,
      borderRadius: BorderRadius.circular(4),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Hero(
          tag: photo.id,
          child: Image(
            image: photo.image,
            fit: BoxFit.cover,
            excludeFromSemantics: true,
            errorBuilder: (_, _, _) => Center(
              child: Icon(
                Icons.image_not_supported_outlined,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
