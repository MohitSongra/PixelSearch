import 'package:flutter/material.dart';
import '../models/photo.dart';
import '../features/viewer/photo_viewer.dart';
import 'photo_tile.dart';

/// A responsive grid of photo tiles. Tapping opens the full-screen viewer
/// (with a hero transition) scoped to the given [photos] list.
class PhotoGrid extends StatelessWidget {
  final List<Photo> photos;
  final EdgeInsets padding;
  const PhotoGrid({
    super.key,
    required this.photos,
    this.padding = const EdgeInsets.all(12),
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final columns = width > 900 ? 4 : (width > 600 ? 3 : 2);

    return GridView.builder(
      padding: padding,
      physics: const AlwaysScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.82,
      ),
      itemCount: photos.length,
      itemBuilder: (context, i) {
        final photo = photos[i];
        return PhotoTile(
          photo: photo,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => PhotoViewerScreen(photos: photos, initialIndex: i),
            ),
          ),
        );
      },
    );
  }
}
