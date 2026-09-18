import 'package:flutter/material.dart';
import '../../models/photo.dart';

/// Uses the existing indexed thumbnail/device recovery path, without writes.
class TimelinePhotoImage extends StatelessWidget {
  const TimelinePhotoImage({
    super.key,
    required this.photo,
    this.fit = BoxFit.cover,
  });

  final Photo photo;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) => Image(
    image: photo.image,
    fit: fit,
    semanticLabel: photo.displayTitle,
    errorBuilder: (_, _, _) => const Center(
      child: Icon(
        Icons.broken_image_outlined,
        semanticLabel: 'Photo unavailable',
        size: 40,
      ),
    ),
  );
}
