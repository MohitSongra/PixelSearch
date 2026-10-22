import 'package:flutter/material.dart';
import '../models/photo.dart';
import '../features/viewer/photo_viewer.dart';
import 'photo_tile.dart';
import '../domain/search/search_response.dart';

/// A responsive grid of photo tiles. Tapping opens the full-screen viewer
/// (with a hero transition) scoped to the given [photos] list.
class PhotoGrid extends StatelessWidget {
  final List<Photo> photos;
  final EdgeInsets padding;
  final SearchResponse? searchResponse;
  const PhotoGrid({
    super.key,
    required this.photos,
    this.padding = const EdgeInsets.fromLTRB(12, 8, 12, 24),
    this.searchResponse,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = (constraints.maxWidth / 125).floor().clamp(3, 8);
        return GridView.builder(
          padding: padding,
          physics: const AlwaysScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 3,
            mainAxisSpacing: 3,
            childAspectRatio: 1,
          ),
          itemCount: photos.length,
          itemBuilder: (context, i) {
            final photo = photos[i];
            return PhotoTile(
              photo: photo,
              onTap: () => Navigator.of(context, rootNavigator: true).push(
                MaterialPageRoute(
                  builder: (_) => PhotoViewerScreen(
                    photos: photos,
                    initialIndex: i,
                    searchResponse: searchResponse,
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
